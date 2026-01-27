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
    public var trackingStatus: TrackingStatus
    public var gpsStatus: String
    
    public var topSpeed: String
    public var topLeanAngle: String
    
    public var cameraPosition: MapCameraPosition
    
    public var liveStats: LiveStats
    
    public init(
        trackingStatus: TrackingStatus,
        gpsStatus: String,
        topSpeed: String = "0",
        topLeanAngle: String,
        cameraPosition: MapCameraPosition,
        liveStats: LiveStats
    ) {
        self.trackingStatus = trackingStatus
        self.gpsStatus = gpsStatus
        self.topSpeed = topSpeed
        self.topLeanAngle = topLeanAngle
        self.cameraPosition = cameraPosition
        self.liveStats = liveStats
    }
}

public struct LiveStats {
    public let speed: String
    public let leanAngle: String
    public let location: Location
    public let distance: String
    public let duration: String
    
    public init(speed: String,
                leanAngle: String,
                location: Location,
                distance: String,
                duration: String) {
        self.speed = speed
        self.leanAngle = leanAngle
        self.location = location
        self.distance = distance
        self.duration = duration
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
