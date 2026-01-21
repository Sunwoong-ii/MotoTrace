//  RidingStore.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/21.
//

import SwiftUI
import CoreSensorsInterface
import CoreTrackingInterface
import FeatureTourInterface

@MainActor
internal final class TourStore: ObservableObject {
    @Published private(set) var state: RidingState
    
    private let sensors: CoreSensorsInterface
    private let analyzer: TrackingAnalyzerInterface
    private var locationTask: Task<Void, Never>?
    private var motionTask: Task<Void, Never>?
    
    internal init(
        state: RidingState = RidingState(),
        sensors: CoreSensorsInterface = CoreSensorsFactory.create(),
        analyzer: TrackingAnalyzerInterface = TrackingAnalyzerFactory.create()
    ) {
        self.state = state
        self.sensors = sensors
        self.analyzer = analyzer
    }
    
    internal func send(_ intent: RidingIntent) {
        switch intent {
        case .startTracking:
            startTracking()
        case .stopTracking:
            stopTracking()
        }
    }
}

private extension RidingStore {
    func startTracking() {
        guard locationTask == nil, motionTask == nil else { return }
        state.isRiding = true
        
        sensors.requestWhenInUseAuthorization()
        sensors.start()
        
        locationTask = Task { [weak self] in
            guard let self else { return }
            for await location in sensors.locationStream() {
                let trackingData = TrackingData(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    timestamp: location.timestamp
                )
                analyzer.recordLocation(trackingData)
                
                let events = analyzer.updateSpeed(
                    SpeedData(timestamp: location.timestamp, speedKmh: location.speedKmh)
                )
                _ = analyzer.mapEventsToLocations(events)
            }
        }
        
        motionTask = Task { [weak self] in
            guard let self else { return }
            for await motion in sensors.motionStream() {
                let events = analyzer.updateAttitude(
                    AttitudeData(
                        timestamp: motion.timestamp,
                        rollDegrees: motion.rollDegrees,
                        pitchDegrees: motion.pitchDegrees
                    )
                )
                _ = analyzer.mapEventsToLocations(events)
            }
        }
    }
    
    func stopTracking() {
        state.isRiding = false
        sensors.stop()
        locationTask?.cancel()
        motionTask?.cancel()
        locationTask = nil
        motionTask = nil
    }
}
