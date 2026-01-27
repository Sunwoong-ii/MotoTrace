//
//  TourEvent.swift
//  CoreDataStorageInterface
//
//  Created by MotoTrace Team.
//

import Foundation
import SwiftData

/// 투어 중 발생한 특이 이벤트 모델 (DB)
@Model
public final class TourEvent {
    @Attribute(.unique) public var id: UUID
    
    /// 이벤트 타입
    public var type: TourEventType
    
    /// 발생 시작 시간
    public var startTime: Date
    
    /// 종료 시간 (급가속/감속 등 지속되는 이벤트의 경우)
    public var endTime: Date?
    
    /// 이벤트 발생 시점의 속도 (km/h)
    public var startSpeed: Double
    
    /// 이벤트 종료 시점의 속도 (km/h)
    public var endSpeed: Double?
    
    /// 이벤트 발생 시점의 좌표 위도
    public var latitude: Double
    
    /// 이벤트 발생 시점의 좌표 경도
    public var longitude: Double
    
    /// 소속된 투어 기록 (역방향 참조)
    public var record: TourRecord?
    
    public init(
        id: UUID = UUID(),
        type: TourEventType,
        startTime: Date,
        startSpeed: Double,
        latitude: Double,
        longitude: Double,
        endTime: Date? = nil,
        endSpeed: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.startSpeed = startSpeed
        self.latitude = latitude
        self.longitude = longitude
        self.endTime = endTime
        self.endSpeed = endSpeed
    }
}

/// 투어 이벤트 타입 정의
public enum TourEventType: String, Codable, CaseIterable {
    /// 급가속
    case rapidAcceleration
    /// 급감속
    case rapidDeceleration
    /// 뱅킹각 (최대 뱅킹각 갱신 시점 등)
    case leanAngle
}
