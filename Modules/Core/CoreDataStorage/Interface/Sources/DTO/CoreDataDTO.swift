//
//  CoreDataDTO.swift
//  CoreDataStorageInterface
//
//  Created by MotoTrace Team.
//

import Foundation

public struct TripStats {
    public let duration: TimeInterval
    public let distance: Double
    public let avgSpeed: Double
    
    public init(
        duration: TimeInterval,
        distance: Double,
        avgSpeed: Double
    ) {
        self.duration = duration
        self.distance = distance
        self.avgSpeed = avgSpeed
    }
}

/// GPS 신호 상태
public enum GPSStatus: String, Equatable {
    case good
    case weak
    case none
}

// 투어 기록 DTO
public struct TourRecordDTO: Identifiable, Codable {
    public let id: UUID
    public let duration: TimeInterval
    public let distance: Double
    public let avgSpeed: Double
    public let topSpeed: Double
    public let maxLeanAngle: Double
    public let tourName: String
    public let createdAt: Date
    public let locations: [LocationPointDTO]
    public let events: [TourEventDTO]
    
    public init(
        id: UUID = UUID(),
        duration: TimeInterval = .zero,
        distance: Double = 0,
        avgSpeed: Double = 0,
        topSpeed: Double = 0,
        maxLeanAngle: Double = 0,
        tourName: String,
        createdAt: Date = Date(),
        locations: [LocationPointDTO] = [],
        events: [TourEventDTO] = []
    ) {
        self.id = id
        self.duration = duration
        self.distance = distance
        self.avgSpeed = avgSpeed
        self.topSpeed = topSpeed
        self.maxLeanAngle = maxLeanAngle
        self.tourName = tourName
        self.createdAt = createdAt
        self.locations = locations
        self.events = events
    }
}

// 투어 이벤트 DTO
public struct TourEventDTO: Identifiable, Codable {
    public let id: UUID
    public let type: String // RawValue of TourEventType
    
    public let startTime: Date?
    public let endTime: Date?
    
    public let startSpeed: Double
    public let endSpeed: Double?
    
    public let latitude: Double
    public let longitude: Double
    
    public let leanAngle: Double?
    
    public init(
        id: UUID = UUID(),
        type: String,
        startTime: Date?,
        endTime: Date?,
        startSpeed: Double,
        endSpeed: Double?,
        latitude: Double,
        longitude: Double,
        leanAngle: Double?
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.startSpeed = startSpeed
        self.endSpeed = endSpeed
        self.latitude = latitude
        self.longitude = longitude
        self.leanAngle = leanAngle
    }
}

// 위치 정보 DTO
public struct LocationPointDTO: Identifiable, Codable {
    public let id: UUID
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    public let speed: Double
    
    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        speed: Double
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.speed = speed
    }
}
