//  Models.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//
import Foundation
import CoreLocation

public struct Location: Codable {
    public let latitude: Double
    public let longitude: Double
    public let speedKmh: Double
    public let horizontalAccuracy: Double
    public let timestamp: Date
    
    public init(
        latitude: Double,
        longitude: Double,
        speedKmh: Double,
        horizontalAccuracy: Double,
        timestamp: Date
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.speedKmh = speedKmh
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
    }
}

public struct Motion: Codable {
    public let rollDegrees: Double
    public let pitchDegrees: Double
    public let yawDegrees: Double
    public let timestamp: Date
    
    public init(rollDegrees: Double, pitchDegrees: Double, yawDegrees: Double, timestamp: Date) {
        self.rollDegrees = rollDegrees
        self.pitchDegrees = pitchDegrees
        self.yawDegrees = yawDegrees
        self.timestamp = timestamp
    }
}
