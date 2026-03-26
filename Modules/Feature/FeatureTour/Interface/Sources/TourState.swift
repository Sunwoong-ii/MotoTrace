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
    public var routeCoordinates: [CLLocationCoordinate2D]
    
    /// 새 트래킹 세션 시작마다 갱신 — MapPolyline 캐시 강제 초기화용
    public var mapSessionId: UUID
    
    public init(
        tourName: String = "",
        trackingStatus: TrackingStatus = .idle,
        gpsStatus: String = "GPS 대기 중",
        topSpeed: String = "0",
        topLeanAngle: String = "0",
        cameraPosition: MapCameraPosition = .automatic,
        liveStats: LiveStats = LiveStats(),
        routeCoordinates: [CLLocationCoordinate2D] = [],
        mapSessionId: UUID = UUID()
    ) {
        self.tourName = tourName
        self.trackingStatus = trackingStatus
        self.gpsStatus = gpsStatus
        self.topSpeed = topSpeed
        self.topLeanAngle = topLeanAngle
        self.cameraPosition = cameraPosition
        self.liveStats = liveStats
        self.routeCoordinates = routeCoordinates
        self.mapSessionId = mapSessionId
    }
}
