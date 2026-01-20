import Foundation
import CoreTrackingInterface

internal final class TrackingAnalyzer: TrackingAnalyzerInterface {
    private var thresholds: TrackingThresholds
    private var lastSpeedSample: SpeedSample?
    private var movingTimeSeconds: TimeInterval = 0
    private var movingDistanceKm: Double = 0
    private var leanZeroOffset: Double = 0
    private var routePoints: [TrackingData] = []
    
    internal init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    internal func updateSpeed(_ sample: SpeedSample) -> [TrackingEvent] {
        defer { lastSpeedSample = sample }
        var events: [TrackingEvent] = []
        
        if let previous = lastSpeedSample {
            let deltaTime = sample.timestamp.timeIntervalSince(previous.timestamp)
            if deltaTime > 0 {
                let deltaSpeed = sample.speedKmh - previous.speedKmh
                let accel = deltaSpeed / deltaTime
                
                if accel >= thresholds.accelerationKmhPerSec {
                    events.append(
                        TrackingEvent(
                            type: .rapidAcceleration,
                            timestamp: sample.timestamp,
                            value: accel
                        )
                    )
                } else if accel <= -thresholds.decelerationKmhPerSec {
                    events.append(
                        TrackingEvent(
                            type: .rapidDeceleration,
                            timestamp: sample.timestamp,
                            value: accel
                        )
                    )
                }
                
                if sample.speedKmh >= thresholds.stopSpeedKmh {
                    movingTimeSeconds += deltaTime
                    movingDistanceKm += (sample.speedKmh * (deltaTime / 3600.0))
                }
            }
        }
        
        return events
    }
    
    internal func updateLeanAngle(_ sample: LeanAngleSample) -> [TrackingEvent] {
        let relativeAngle = sample.angleDegrees - leanZeroOffset
        if abs(relativeAngle) >= thresholds.minLeanAngleDegrees {
            return [
                TrackingEvent(
                    type: .leanAngle,
                    timestamp: sample.timestamp,
                    value: relativeAngle
                )
            ]
        }
        return []
    }
    
    internal func recordLocation(_ data: TrackingData) {
        routePoints.append(data)
    }
    
    internal func route() -> [TrackingData] {
        routePoints
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
    
    internal func calibrateLeanZero(angleDegrees: Double) {
        leanZeroOffset = angleDegrees
    }
    
    internal func reset() {
        lastSpeedSample = nil
        movingTimeSeconds = 0
        movingDistanceKm = 0
        leanZeroOffset = 0
        routePoints.removeAll()
    }
}
