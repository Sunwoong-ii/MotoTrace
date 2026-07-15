import Foundation
import CoreLocation

/// 지도에 표시할 주행 이벤트 마커 — 저장소 DTO(String rawValue)를 View까지
/// 흘리지 않기 위한 Feature 전용 표현. 표시 문자열은 Store에서 조립을 끝낸다
public struct RideEventMarker: Identifiable, Equatable {
    public enum EventType: String {
        case rapidAcceleration
        case rapidDeceleration
        case leanAngle
    }

    public let id: UUID
    public let type: EventType
    /// 이벤트 발생 순간의 위치 (세 타입 공통) — 마커를 꽂을 좌표
    public let coordinate: CLLocationCoordinate2D
    /// 예: "45→82 (2.1s)", "38° 65km/h"
    public let displayValue: String

    public init(id: UUID, type: EventType, coordinate: CLLocationCoordinate2D, displayValue: String) {
        self.id = id
        self.type = type
        self.coordinate = coordinate
        self.displayValue = displayValue
    }

    // CLLocationCoordinate2D가 Equatable이 아니라 수동 구현
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.type == rhs.type
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.displayValue == rhs.displayValue
    }
}

public struct HistoryDetailState {
    public var tourName: String
    public var createdAt: Date
    public var duration: TimeInterval
    public var distance: Double
    public var avgSpeed: Double
    public var topSpeed: Double
    public var maxLeanAngle: Double
    public var routeCoordinates: [CLLocationCoordinate2D]
    public var eventMarkers: [RideEventMarker]

    public init(
        tourName: String = "",
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        distance: Double = 0,
        avgSpeed: Double = 0,
        topSpeed: Double = 0,
        maxLeanAngle: Double = 0,
        routeCoordinates: [CLLocationCoordinate2D] = [],
        eventMarkers: [RideEventMarker] = []
    ) {
        self.tourName = tourName
        self.createdAt = createdAt
        self.duration = duration
        self.distance = distance
        self.avgSpeed = avgSpeed
        self.topSpeed = topSpeed
        self.maxLeanAngle = maxLeanAngle
        self.routeCoordinates = routeCoordinates
        self.eventMarkers = eventMarkers
    }
}
