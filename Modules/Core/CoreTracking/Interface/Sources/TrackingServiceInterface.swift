import Foundation
import CoreLocation  // Apple의 CoreLocation 프레임워크 사용

/// 위치 추적 서비스 프로토콜
public protocol TrackingServiceInterface {
    // 위치 추적 메서드
}

public struct SpeedSample: Codable {
    public let timestamp: Date
    public let speedKmh: Double
    
    public init(timestamp: Date, speedKmh: Double) {
        self.timestamp = timestamp
        self.speedKmh = speedKmh
    }
}

public struct LeanAngleSample: Codable {
    public let timestamp: Date
    public let angleDegrees: Double
    
    public init(timestamp: Date, angleDegrees: Double) {
        self.timestamp = timestamp
        self.angleDegrees = angleDegrees
    }
}

public struct TrackingThresholds: Codable {
    public let accelerationKmhPerSec: Double
    public let decelerationKmhPerSec: Double
    public let minLeanAngleDegrees: Double
    public let stopSpeedKmh: Double
    
    public init(
        accelerationKmhPerSec: Double,
        decelerationKmhPerSec: Double,
        minLeanAngleDegrees: Double,
        stopSpeedKmh: Double
    ) {
        self.accelerationKmhPerSec = accelerationKmhPerSec
        self.decelerationKmhPerSec = decelerationKmhPerSec
        self.minLeanAngleDegrees = minLeanAngleDegrees
        self.stopSpeedKmh = stopSpeedKmh
    }
}

public struct TourStats: Codable {
    public let movingTimeSeconds: TimeInterval
    public let movingDistanceKm: Double
    public let averageSpeedKmh: Double
    
    public init(movingTimeSeconds: TimeInterval, movingDistanceKm: Double, averageSpeedKmh: Double) {
        self.movingTimeSeconds = movingTimeSeconds
        self.movingDistanceKm = movingDistanceKm
        self.averageSpeedKmh = averageSpeedKmh
    }
}

public enum TrackingEventType: String, Codable {
    case rapidAcceleration
    case rapidDeceleration
    case leanAngle
}

public struct TrackingEvent: Codable {
    public let type: TrackingEventType
    public let timestamp: Date
    public let value: Double
    
    public init(type: TrackingEventType, timestamp: Date, value: Double) {
        self.type = type
        self.timestamp = timestamp
        self.value = value
    }
}

public protocol TrackingAnalyzerInterface {
    func updateSpeed(_ sample: SpeedSample) -> [TrackingEvent]
    func updateLeanAngle(_ sample: LeanAngleSample) -> [TrackingEvent]
    func recordLocation(_ data: TrackingData)
    func route() -> [TrackingData]
    func stats() -> TourStats
    func setThresholds(_ thresholds: TrackingThresholds)
    func calibrateLeanZero(angleDegrees: Double)
    func reset()
}

/// 추적 데이터 DTO
public struct TrackingData: Codable {
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    
    public init(latitude: Double, longitude: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}
