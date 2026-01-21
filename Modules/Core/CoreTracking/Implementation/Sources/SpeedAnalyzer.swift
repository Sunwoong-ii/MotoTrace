//  SpeedAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface

internal final class SpeedAnalyzer {
    private var thresholds: TrackingThresholds
    private var lastSpeedData: SpeedData?
    private var movingTimeSeconds: TimeInterval = 0
    private var movingDistanceKm: Double = 0
    
    internal init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    internal func updateSpeed(_ data: SpeedData) -> [TrackingEvent] {
        defer { lastSpeedData = data }
        var events: [TrackingEvent] = []
        
        if let previous = lastSpeedData {
            let deltaTime = data.timestamp.timeIntervalSince(previous.timestamp)
            if deltaTime > 0 {
                let deltaSpeed = data.speedKmh - previous.speedKmh
                let accel = deltaSpeed / deltaTime
                
                if accel >= thresholds.accelerationKmhPerSec {
                    events.append(
                        TrackingEvent(
                            type: .rapidAcceleration,
                            timestamp: data.timestamp,
                            value: accel
                        )
                    )
                } else if accel <= -thresholds.decelerationKmhPerSec {
                    events.append(
                        TrackingEvent(
                            type: .rapidDeceleration,
                            timestamp: data.timestamp,
                            value: accel
                        )
                    )
                }
                
                if data.speedKmh >= thresholds.stopSpeedKmh {
                    movingTimeSeconds += deltaTime
                    movingDistanceKm += (data.speedKmh * (deltaTime / 3600.0))
                }
            }
        }
        
        return events
    }
    
    internal func stats() -> TourStats {
        let averageSpeed: Double
        if movingTimeSeconds > 0 {
            averageSpeed = movingDistanceKm / (movingTimeSeconds / 3600.0)
        } else {
            averageSpeed = 0
        }
        return TourStats(
            movingTimeSeconds: movingTimeSeconds,
            movingDistanceKm: movingDistanceKm,
            averageSpeedKmh: averageSpeed
        )
    }
    
    internal func setThresholds(_ thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    internal func reset() {
        lastSpeedData = nil
        movingTimeSeconds = 0
        movingDistanceKm = 0
    }
}
