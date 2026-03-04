import Foundation
import MapKit
import SwiftUI
import CoreLocation
import CoreTrackingInterface

public enum TrackingStatus {
    case idle      // 대기 중 (아직 시작 안 함)
    case tracking  // 기록 중
    case paused    // 일시 정지됨
}

/// 라이딩 Feature의 State (MVI 패턴)
public struct TourState {
    public var tourName: String
    public var trackingStatus: TrackingStatus
    public var gpsStatus: String
    
    public var topSpeed: String
    public var topLeanAngle: String
    
    public var cameraPosition: MapCameraPosition
    
    public var liveStats: LiveStats
    
    public init(
        tourName: String = "",
        trackingStatus: TrackingStatus = .idle,
        gpsStatus: String = "GPS 대기 중",
        topSpeed: String = "0",
        topLeanAngle: String = "0",
        cameraPosition: MapCameraPosition = .automatic,
        liveStats: LiveStats = LiveStats()
    ) {
        self.tourName = tourName
        self.trackingStatus = trackingStatus
        self.gpsStatus = gpsStatus
        self.topSpeed = topSpeed
        self.topLeanAngle = topLeanAngle
        self.cameraPosition = cameraPosition
        self.liveStats = liveStats
    }
}

public struct LiveStats {
    public let speed: String          // 현재 속도 (live)
    public let leanAngle: String      // 현재 뱅킹각 (live)
    public let location: Location     // 현재 위치
    public let distance: String       // 총 거리
    public let duration: String       // 총 시간
    public let avgSpeed: String       // 평균 속도
    
    public init(
        speed: String = "0",
        leanAngle: String = "0",
        location: Location = Location(latitude: 0, longitude: 0, timestamp: Date()),
        distance: String = "0.0",
        duration: String = "00:00:00",
        avgSpeed: String = "0"
    ) {
        self.speed = speed
        self.leanAngle = leanAngle
        self.location = location
        self.distance = distance
        self.duration = duration
        self.avgSpeed = avgSpeed
    }
}

public struct DisplayValue {
    public let value: String
    public let unit: String
    
    public init(value: String, unit: String) {
        self.value = value
        self.unit = unit
    }
}
