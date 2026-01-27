//
//  TrackingData.swift
//  CoreDataStorageInterface
//
//  Created by MotoTrace Team.
//

import Foundation

/// 실시간 트래킹 중 발생하는 데이터 모델 (DB 저장 전)
public struct TrackingData: Equatable {
    /// 총 주행 시간 (초)
    public let duration: TimeInterval
    
    /// 총 주행 거리 (미터)
    public let distance: Double
    
    /// 현재까지의 평균 속도 (km/h)
    public let avgSpeed: Double
    
    /// 현재까지의 최고 속도 (km/h)
    public let topSpeed: Double
    
    /// 현재가지의 최대 뱅킹각 (도)
    public let maxLeanAngle: Double
    
    /// 현재 실시간 속도 (km/h)
    public let liveSpeed: Double
    
    /// 현재 실시간 뱅킹각 (도)
    public let liveLeanAngle: Double
    
    /// GPS 수신 상태
    public let gpsStatus: GPSStatus
    
    public init(
        duration: TimeInterval,
        distance: Double,
        avgSpeed: Double,
        topSpeed: Double,
        maxLeanAngle: Double,
        liveSpeed: Double,
        liveLeanAngle: Double,
        gpsStatus: GPSStatus
    ) {
        self.duration = duration
        self.distance = distance
        self.avgSpeed = avgSpeed
        self.topSpeed = topSpeed
        self.maxLeanAngle = maxLeanAngle
        self.liveSpeed = liveSpeed
        self.liveLeanAngle = liveLeanAngle
        self.gpsStatus = gpsStatus
    }
}

/// GPS 신호 상태
public enum GPSStatus: String, Equatable {
    case good
    case weak
    case none
}

/// 투어 기록 DTO
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

/// 투어 이벤트 DTO
public struct TourEventDTO: Identifiable, Codable {
    public let id: UUID
    public let type: String // RawValue of TourEventType
    public let startTime: Date
    public let endTime: Date?
    public let startSpeed: Double
    public let endSpeed: Double?
    public let latitude: Double
    public let longitude: Double
    
    public init(
        id: UUID = UUID(),
        type: String,
        startTime: Date,
        endTime: Date? = nil,
        startSpeed: Double,
        endSpeed: Double? = nil,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.startSpeed = startSpeed
        self.endSpeed = endSpeed
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// 위치 정보 DTO
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
