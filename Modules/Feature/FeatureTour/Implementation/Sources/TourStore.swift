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
    
    internal init(dependencies: TourDependencies) {
        self.state = dependencies.initialState
        self.sensors = dependencies.sensors
        self.analyzer = dependencies.analyzer
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

private extension TourStore {
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
                _ = analyzer.mapSpeedEventsToLocations(events)
            }
        }
        
        motionTask = Task { [weak self] in
            guard let self else { return }
            for await motion in sensors.motionStream() {
                let accelerationG = sqrt(
                    motion.userAccelerationX * motion.userAccelerationX +
                    motion.userAccelerationY * motion.userAccelerationY +
                    motion.userAccelerationZ * motion.userAccelerationZ
                )
                analyzer.updateAcceleration(
                    AccelerationData(timestamp: motion.timestamp, accelerationG: accelerationG)
                )
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
