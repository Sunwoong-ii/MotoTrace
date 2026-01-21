//  TrackingServiceInterface.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreLocation

/// 위치 추적 서비스 프로토콜
public protocol TrackingServiceInterface {
    // 위치 추적 메서드
}

public struct SpeedData: Codable {
    public let timestamp: Date
    public let speedKmh: Double
    
    public init(timestamp: Date, speedKmh: Double) {
        self.timestamp = timestamp
        self.speedKmh = speedKmh
    }
}

public struct LeanAngleData: Codable {
    public let timestamp: Date
    public let angleDegrees: Double
    
    public init(timestamp: Date, angleDegrees: Double) {
        self.timestamp = timestamp
        self.angleDegrees = angleDegrees
    }
}

public struct AttitudeData: Codable {
    public let timestamp: Date
    public let rollDegrees: Double
    public let pitchDegrees: Double
    
    public init(timestamp: Date, rollDegrees: Double, pitchDegrees: Double) {
        self.timestamp = timestamp
        self.rollDegrees = rollDegrees
        self.pitchDegrees = pitchDegrees
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

public struct TrackingEventLocation: Codable {
    public let event: TrackingEvent
    public let location: TrackingData?
    
    public init(event: TrackingEvent, location: TrackingData?) {
        self.event = event
        self.location = location
    }
}

public protocol TrackingAnalyzerInterface {
    func updateSpeed(_ data: SpeedData) -> [TrackingEvent]
    func updateLeanAngle(_ data: LeanAngleData) -> [TrackingEvent]
    func updateAttitude(_ data: AttitudeData) -> [TrackingEvent]
    func mapEventsToLocations(_ events: [TrackingEvent]) -> [TrackingEventLocation]
    func recordLocation(_ data: TrackingData)
    func route() -> [TrackingData]
    func stats() -> TourStats
    func setThresholds(_ thresholds: TrackingThresholds)
    func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double)
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
