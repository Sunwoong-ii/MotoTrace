//  SpeedAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface

internal final class SpeedAnalyzer {
    private struct MotionTrigger {
        let timestamp: Date
        let accelerationKmhPerSec: Double
    }
    
    private enum ActiveSpeedEvent {
        case acceleration(start: SpeedData)
        case deceleration(start: SpeedData)
    }
    
    private var thresholds: TrackingThresholds
    private var lastSpeedData: SpeedData?
    private var movingTimeSeconds: TimeInterval = 0
    private var movingDistanceKm: Double = 0
    private var lastMotionTrigger: MotionTrigger?
    private var activeEvent: ActiveSpeedEvent?
    
    internal init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    internal func updateSpeed(_ currentSpeedData: SpeedData) -> [SpeedChangeEvent] {
        defer { lastSpeedData = currentSpeedData }
        var events: [SpeedChangeEvent] = []
        
        guard let previous = lastSpeedData else { return events }
        let deltaTime = currentSpeedData.timestamp.timeIntervalSince(previous.timestamp)
        
        if deltaTime > 0 {
            let deltaSpeed = currentSpeedData.speedKmh - previous.speedKmh
            let accel = deltaSpeed / deltaTime
            let motionTriggerActive = isMotionTriggerActive(at: currentSpeedData.timestamp)
            
            let triggerAllowed = motionTriggerActive || lastMotionTrigger == nil
            switch activeEvent {
            case nil:
                if accel >= thresholds.accelerationKmhPerSec && triggerAllowed {
                    activeEvent = .acceleration(start: previous)
                } else if accel <= -thresholds.decelerationKmhPerSec && triggerAllowed {
                    activeEvent = .deceleration(start: previous)
                }
            case .acceleration(let startSpeedData):
                if accel < thresholds.accelerationKmhPerSec {
                    if let event = makeSpeedChangeEvent(
                        type: .rapidAcceleration,
                        start: startSpeedData,
                        end: currentSpeedData
                    ) {
                        events.append(event)
                    }
                    activeEvent = nil
                } else if accel <= -thresholds.decelerationKmhPerSec && triggerAllowed {
                    if let event = makeSpeedChangeEvent(
                        type: .rapidAcceleration,
                        start: startSpeedData,
                        end: currentSpeedData
                    ) {
                        events.append(event)
                    }
                    activeEvent = .deceleration(start: previous)
                }
            case .deceleration(let startSpeedData):
                if accel > -thresholds.decelerationKmhPerSec {
                    if let event = makeSpeedChangeEvent(
                        type: .rapidDeceleration,
                        start: startSpeedData,
                        end: currentSpeedData
                    ) {
                        events.append(event)
                    }
                    activeEvent = nil
                } else if accel >= thresholds.accelerationKmhPerSec && triggerAllowed {
                    if let event = makeSpeedChangeEvent(
                        type: .rapidDeceleration,
                        start: startSpeedData,
                        end: currentSpeedData
                    ) {
                        events.append(event)
                    }
                    activeEvent = .acceleration(start: previous)
                }
            }
            
            if currentSpeedData.speedKmh >= thresholds.stopSpeedKmh {
                movingTimeSeconds += deltaTime
                movingDistanceKm += (currentSpeedData.speedKmh * (deltaTime / 3600.0))
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

    internal func updateAcceleration(_ data: AccelerationData) {
        let accelerationKmhPerSec = data.accelerationG * 9.81 * 3.6
        lastMotionTrigger = MotionTrigger(
            timestamp: data.timestamp,
            accelerationKmhPerSec: accelerationKmhPerSec
        )
    }
    
    internal func reset() {
        lastSpeedData = nil
        movingTimeSeconds = 0
        movingDistanceKm = 0
        lastMotionTrigger = nil
        activeEvent = nil
    }

    func isMotionTriggerActive(at timestamp: Date) -> Bool {
        guard let trigger = lastMotionTrigger else { return false }
        let delta = abs(trigger.timestamp.timeIntervalSince(timestamp))
        if delta > 0.6 {
            return false
        }
        return abs(trigger.accelerationKmhPerSec) >= thresholds.accelerationKmhPerSec
    }
    
    func makeSpeedChangeEvent(
        type: SpeedChangeEventType,
        start: SpeedData,
        end: SpeedData
    ) -> SpeedChangeEvent? {
        let duration = end.timestamp.timeIntervalSince(start.timestamp)
        guard duration > 0 else { return nil }
        return SpeedChangeEvent(
            type: type,
            startTimestamp: start.timestamp,
            endTimestamp: end.timestamp,
            startSpeedKmh: start.speedKmh,
            endSpeedKmh: end.speedKmh,
            durationSeconds: duration
        )
    }
}
