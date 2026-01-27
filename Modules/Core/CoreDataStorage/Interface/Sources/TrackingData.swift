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
