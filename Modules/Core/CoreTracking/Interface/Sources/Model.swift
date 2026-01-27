//
//  Model.swift
//  CoreTrackingInterface
//
//  Created by 웅 on 1/22/26.
//

import Foundation

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

public enum SpeedChangeEventType: String, Codable {
    case rapidAcceleration
    case rapidDeceleration
}

public struct SpeedChangeEvent: Codable {
    public let type: SpeedChangeEventType
    public let startTimestamp: Date
    public let endTimestamp: Date
    public let startSpeedKmh: Double
    public let endSpeedKmh: Double
    public let durationSeconds: TimeInterval
    public let location: Location
    
    public init(
        type: SpeedChangeEventType,
        startTimestamp: Date,
        endTimestamp: Date,
        startSpeedKmh: Double,
        endSpeedKmh: Double,
        durationSeconds: TimeInterval,
        location: Location
    ) {
        self.type = type
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.startSpeedKmh = startSpeedKmh
        self.endSpeedKmh = endSpeedKmh
        self.durationSeconds = durationSeconds
        self.location = location
    }
}

public struct Location: Codable {
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    
    public init(latitude: Double, longitude: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}
