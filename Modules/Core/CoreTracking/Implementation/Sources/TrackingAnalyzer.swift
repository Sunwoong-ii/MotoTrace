//  TrackingAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface

internal final class TrackingAnalyzer: TrackingAnalyzerInterface {
    private let maxLocationBufferCount = 120
    private var thresholds: TrackingThresholds
    private var speedAnalyzer: SpeedAnalyzer
    private var leanAnalyzer: LeanAnalyzer
    private var routePoints: [TrackingData] = []
    private var recentLocations: [TrackingData] = []
    
    internal init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
        self.speedAnalyzer = SpeedAnalyzer(thresholds: thresholds)
        self.leanAnalyzer = LeanAnalyzer(thresholds: thresholds)
    }
    
    internal func updateSpeed(_ data: SpeedData) -> [TrackingEvent] {
        speedAnalyzer.updateSpeed(data)
    }
    
    internal func updateLeanAngle(_ data: LeanAngleData) -> [TrackingEvent] {
        leanAnalyzer.updateLeanAngle(data)
    }

    internal func updateAttitude(_ data: AttitudeData) -> [TrackingEvent] {
        leanAnalyzer.updateAttitude(data)
    }

    internal func mapEventsToLocations(_ events: [TrackingEvent]) -> [TrackingEventLocation] {
        events.map { event in
            TrackingEventLocation(
                event: event,
                location: closestLocation(to: event.timestamp)
            )
        }
    }
    
    internal func recordLocation(_ data: TrackingData) {
        routePoints.append(data)
        recentLocations.append(data)
        trimLocationBuffer()
    }
    
    internal func route() -> [TrackingData] {
        routePoints
    }
    
    internal func stats() -> TourStats {
        speedAnalyzer.stats()
    }
    
    internal func setThresholds(_ thresholds: TrackingThresholds) {
        self.thresholds = thresholds
        speedAnalyzer.setThresholds(thresholds)
        leanAnalyzer.setThresholds(thresholds)
    }
    
    internal func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double) {
        leanAnalyzer.calibrateLeanZero(rollDegrees: rollDegrees, pitchDegrees: pitchDegrees)
    }
    
    internal func reset() {
        speedAnalyzer.reset()
        leanAnalyzer.reset()
        routePoints.removeAll()
        recentLocations.removeAll()
    }
}

private extension TrackingAnalyzer {
    func closestLocation(to timestamp: Date) -> TrackingData? {
        guard !recentLocations.isEmpty else { return nil }
        return recentLocations.min { lhs, rhs in
            abs(lhs.timestamp.timeIntervalSince(timestamp)) <
                abs(rhs.timestamp.timeIntervalSince(timestamp))
        }
    }
    
    func trimLocationBuffer() {
        if recentLocations.count > maxLocationBufferCount {
            recentLocations.removeFirst(recentLocations.count - maxLocationBufferCount)
        }
    }
}
