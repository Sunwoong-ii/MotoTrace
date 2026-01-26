import Foundation
import MapKit
import SwiftUI
import CoreLocation

public enum TrackingStatus {
    case idle      // 대기 중 (아직 시작 안 함)
    case tracking  // 기록 중
    case paused    // 일시 정지됨
}

/// 라이딩 Feature의 State (MVI 패턴)
public struct TourState {
    public var trackingStatus: TrackingStatus
    public var cameraPosition: MapCameraPosition
    
    public init(trackingStatus: TrackingStatus = .idle,
                cameraPosition: MapCameraPosition = .automatic) {
        self.trackingStatus = trackingStatus
        self.cameraPosition = cameraPosition
    }
}
