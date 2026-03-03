//
//  Model.swift
//  CoreTrackingInterface
//
//  Created by 웅 on 1/22/26.
//

import Foundation

public struct LocationSnapshot: Codable {
    public let timestamp: Date
    public let speedKmh: Double
    public let location: Location
    
    public init(
        timestamp: Date,
        speedKmh: Double,
        location: Location
    ) {
        self.timestamp = timestamp
        self.speedKmh = speedKmh
        self.location = location
    }
}

public struct MotionSnapshot: Codable {
    public let timestamp: Date
    public let rollDegrees: Double
    public let pitchDegrees: Double
    
    public let userAccelerationX: Double
    public let userAccelerationY: Double
    public let userAccelerationZ: Double
    
    public init(
        timestamp: Date,
        rollDegrees: Double,
        pitchDegrees: Double,
        userAccelerationX: Double,
        userAccelerationY: Double,
        userAccelerationZ: Double
    ) {
        self.timestamp = timestamp
        self.rollDegrees = rollDegrees
        self.pitchDegrees = pitchDegrees
        self.userAccelerationX = userAccelerationX
        self.userAccelerationY = userAccelerationY
        self.userAccelerationZ = userAccelerationZ
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

public struct LeanAngle: Codable {
    public let angleDegrees: Double
    public let location: Location
    
    public init(angleDegrees: Double, location: Location) {
        self.angleDegrees = angleDegrees
        self.location = location
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

public enum TrackingEventType: String, Codable {
    case rapidAcceleration
    case rapidDeceleration
    case leanAngle
}

public struct TrackingEvent: Codable {
    public let type: TrackingEventType
    public let startTimestamp: Date?
    public let endTimestamp: Date?
    public let startSpeedKmh: Double
    public let endSpeedKmh: Double?
    public let durationSeconds: TimeInterval?
    public let location: Location
    public let leanAngle: Double?
    
    public init(
        type: TrackingEventType,
        startTimestamp: Date? = nil,
        endTimestamp: Date? = nil,
        startSpeedKmh: Double,
        endSpeedKmh: Double? = nil,
        durationSeconds: TimeInterval? = nil,
        location: Location,
        leanAngle: Double? = nil
    ) {
        self.type = type
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.startSpeedKmh = startSpeedKmh
        self.endSpeedKmh = endSpeedKmh
        self.durationSeconds = durationSeconds
        self.location = location
        self.leanAngle = leanAngle
    }
    
    public init(
        type: TrackingEventType = .leanAngle,
        startSpeedKmh: Double,
        location: Location,
        leanAngle: Double
    ) {
        self.type = type
        self.startTimestamp = nil
        self.endTimestamp = nil
        self.startSpeedKmh = startSpeedKmh
        self.endSpeedKmh = nil
        self.durationSeconds = nil
        self.location = location
        self.leanAngle = leanAngle
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
