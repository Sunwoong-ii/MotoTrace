//
//  TourRecord.swift
//  CoreDataStorageInterface
//
//  Created by MotoTrace Team.
//

import Foundation
import SwiftData
import CoreLocation

/// 투어 기록 저장 모델 (DB)
@Model
public final class TourRecord {
    /// 고유 식별자
    @Attribute(.unique) public var id: UUID
    
    /// 투어 총 시간 (초)
    public var duration: TimeInterval
    
    /// 투어 총 거리 (미터)
    public var distance: Double
    
    /// 평균 속도 (km/h)
    public var avgSpeed: Double
    
    /// 최고 속도 (km/h)
    public var topSpeed: Double
    
    /// 최대 뱅킹각 (도)
    public var maxLeanAngle: Double
    
    /// 이동 경로 좌표들
    @Relationship(deleteRule: .cascade)
    public var locations: [LocationPoint]
    
    /// 투어 이름
    public var tourName: String
    
    /// 투어 중 발생한 이벤트들
    @Relationship(deleteRule: .cascade, inverse: \TourEvent.record)
    public var events: [TourEvent]
    
    /// 생성 일시
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        duration: TimeInterval,
        distance: Double,
        avgSpeed: Double,
        topSpeed: Double,
        maxLeanAngle: Double,
        tourName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.duration = duration
        self.distance = distance
        self.avgSpeed = avgSpeed
        self.topSpeed = topSpeed
        self.maxLeanAngle = maxLeanAngle
        self.tourName = tourName
        self.createdAt = createdAt
        self.locations = []
        self.events = []
    }
}

/// 위치 정보 모델 (TourRecord의 하위)
@Model
public final class LocationPoint {
    @Attribute(.unique) public var id: UUID
    public var latitude: Double
    public var longitude: Double
    public var timestamp: Date
    public var speed: Double
    
    public init(id: UUID = UUID(), latitude: Double, longitude: Double, timestamp: Date, speed: Double) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.speed = speed
    }
}
