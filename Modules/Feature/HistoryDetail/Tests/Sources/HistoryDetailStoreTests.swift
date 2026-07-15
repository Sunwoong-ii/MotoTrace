//  HistoryDetailStoreTests.swift
//  HistoryDetailTests
//
//  Created by Woong on 2026/07/14.
//

import XCTest
import CoreLocation
import CoreDataStorageInterface
import HistoryDetailInterface
@testable import HistoryDetail

/// 이벤트 DTO → 지도 마커 매핑 검증 — 표시 문자열 규칙과
/// 불완전한 데이터(모르는 타입·누락 값)의 제외 처리가 핵심
final class HistoryDetailStoreTests: XCTestCase {

    // MARK: - Helpers

    private func makeDTO(
        type: String,
        startTime: Date? = nil,
        endTime: Date? = nil,
        startSpeed: Double = 0,
        endSpeed: Double? = nil,
        latitude: Double = 37.5,
        longitude: Double = 127.0,
        leanAngle: Double? = nil
    ) -> TourEventDTO {
        TourEventDTO(
            type: type,
            startTime: startTime,
            endTime: endTime,
            startSpeed: startSpeed,
            endSpeed: endSpeed,
            latitude: latitude,
            longitude: longitude,
            leanAngle: leanAngle
        )
    }

    // MARK: - 급가속/급감속

    func test_마커변환_급가속_속도변화와_소요시간_포맷() {
        // Given: 45→82km/h, 2.1초 소요
        let base = Date(timeIntervalSince1970: 1_000_000)
        let dto = makeDTO(
            type: "rapidAcceleration",
            startTime: base,
            endTime: base.addingTimeInterval(2.1),
            startSpeed: 45.0,
            endSpeed: 82.0
        )

        // When
        let markers = HistoryDetailStore.makeEventMarkers(from: [dto])

        // Then
        XCTAssertEqual(markers.count, 1)
        XCTAssertEqual(markers.first?.type, .rapidAcceleration)
        XCTAssertEqual(markers.first?.displayValue, "45→82 (2.1s)")
        XCTAssertEqual(markers.first?.coordinate.latitude, 37.5)
        XCTAssertEqual(markers.first?.coordinate.longitude, 127.0)
    }

    func test_마커변환_급감속_종료속도없으면_시작속도만() {
        // Given: 진행 중 저장 등으로 endSpeed가 비어 있는 이벤트
        let dto = makeDTO(type: "rapidDeceleration", startSpeed: 80.4)

        // When
        let markers = HistoryDetailStore.makeEventMarkers(from: [dto])

        // Then
        XCTAssertEqual(markers.first?.type, .rapidDeceleration)
        XCTAssertEqual(markers.first?.displayValue, "80")
    }

    func test_마커변환_시간정보없으면_소요시간_생략() {
        // Given: 속도는 있지만 타임스탬프가 없는 이벤트
        let dto = makeDTO(type: "rapidAcceleration", startSpeed: 45.0, endSpeed: 82.0)

        // When
        let markers = HistoryDetailStore.makeEventMarkers(from: [dto])

        // Then
        XCTAssertEqual(markers.first?.displayValue, "45→82")
    }

    // MARK: - 린앵글

    func test_마커변환_린앵글_각도절댓값과_당시속도_포맷() {
        // Given: 좌측 코너(음수 각도) 38.4°, 65.2km/h
        let dto = makeDTO(type: "leanAngle", startSpeed: 65.2, leanAngle: -38.4)

        // When
        let markers = HistoryDetailStore.makeEventMarkers(from: [dto])

        // Then: 부호(좌/우)는 마커에서 의미 없으므로 절댓값
        XCTAssertEqual(markers.first?.type, .leanAngle)
        XCTAssertEqual(markers.first?.displayValue, "38° 65km/h")
    }

    func test_마커변환_린앵글값_없으면_제외() {
        // Given
        let dto = makeDTO(type: "leanAngle", startSpeed: 60.0, leanAngle: nil)

        // When
        let markers = HistoryDetailStore.makeEventMarkers(from: [dto])

        // Then
        XCTAssertTrue(markers.isEmpty, "각도가 없는 린앵글 이벤트는 마커를 만들지 않아야 합니다")
    }

    // MARK: - 방어 처리

    func test_마커변환_모르는_타입은_제외() {
        // Given: 미래 버전에서 추가될 수 있는 알 수 없는 타입
        let unknown = makeDTO(type: "wheelie", startSpeed: 50.0)
        let known = makeDTO(type: "leanAngle", startSpeed: 60.0, leanAngle: 30.0)

        // When
        let markers = HistoryDetailStore.makeEventMarkers(from: [unknown, known])

        // Then: 모르는 타입만 조용히 제외
        XCTAssertEqual(markers.count, 1)
        XCTAssertEqual(markers.first?.type, .leanAngle)
    }
}
