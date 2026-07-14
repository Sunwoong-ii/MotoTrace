//
//  TrackingAnalyzerRestoreTests.swift
//  CoreTrackingTests
//

import XCTest
import CoreTrackingInterface
@testable import CoreTracking

/// 세션 복구 시딩(restoreStats) 검증
final class TrackingAnalyzerRestoreTests: XCTestCase {

    var sut: TrackingAnalyzer!

    override func setUp() {
        super.setUp()
        sut = TrackingAnalyzer(thresholds: TrackingThresholds(
            accelerationKmhPerSec: 16.7,
            decelerationKmhPerSec: 16.7,
            minLeanAngleDegrees: 30.0,
            stopSpeedKmh: 3.0
        ))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeSnapshot(speedKmh: Double, at date: Date) -> LocationSnapshot {
        LocationSnapshot(
            timestamp: date,
            speedKmh: speedKmh,
            location: Location(latitude: 37.0, longitude: 127.0, timestamp: date),
            course: 0
        )
    }

    // MARK: - 1. 시딩 후 stats가 시딩값에서 이어짐

    func test_restoreStats_시딩후_stats가_시딩값_반환() {
        // Given/When: 복구 시딩 (1.24km, 이동시간 90초, top 100km/h)
        sut.restoreStats(
            movingTimeSeconds: 90,
            movingDistanceKm: 1.24,
            topSpeedKmh: 100,
            topLeanAngleDegrees: 34.7
        )

        // Then: stats/getter가 시딩값을 그대로 반환해야 함
        let stats = sut.stats()
        XCTAssertEqual(stats.movingDistanceKm, 1.24, accuracy: 0.001,
                       "시딩된 거리가 반영되어야 합니다")
        XCTAssertEqual(stats.movingTimeSeconds, 90, accuracy: 0.001,
                       "시딩된 이동 시간이 반영되어야 합니다")
        XCTAssertEqual(sut.topSpeed(), 100, accuracy: 0.001,
                       "시딩된 최고 속도가 반영되어야 합니다")
        XCTAssertEqual(sut.topLeanAngle(), 34.7, accuracy: 0.001,
                       "시딩된 최대 린앵글이 반영되어야 합니다")
    }

    // MARK: - 2. 시딩된 top 미만 속도는 갱신 없음

    func test_updateSpeed_시딩된_topSpeed_미만이면_갱신_안함() {
        // Given: top 100km/h로 시딩
        sut.restoreStats(movingTimeSeconds: 90, movingDistanceKm: 1.24,
                         topSpeedKmh: 100, topLeanAngleDegrees: 0)

        // When: 시딩값보다 낮은 80km/h 주행
        let result = sut.updateSpeed(makeSnapshot(speedKmh: 80, at: Date()))

        // Then: top 갱신이 발생하지 않아야 함 (복구 직후 더 낮은 top이 DB를 덮어쓰는 버그 방지)
        XCTAssertNil(result.topSpeedUpdated,
                     "시딩된 최고 속도보다 낮으면 갱신되지 않아야 합니다")
        XCTAssertEqual(sut.topSpeed(), 100, accuracy: 0.001,
                       "최고 속도는 시딩값을 유지해야 합니다")
    }

    func test_updateSpeed_시딩된_topSpeed_초과면_갱신() {
        // Given
        sut.restoreStats(movingTimeSeconds: 90, movingDistanceKm: 1.24,
                         topSpeedKmh: 100, topLeanAngleDegrees: 0)

        // When: 시딩값을 넘는 120km/h 주행
        let result = sut.updateSpeed(makeSnapshot(speedKmh: 120, at: Date()))

        // Then
        XCTAssertEqual(result.topSpeedUpdated ?? 0, 120, accuracy: 0.001,
                       "시딩값을 넘는 속도는 새 최고 속도로 갱신되어야 합니다")
    }

    // MARK: - 3. 시딩 후 거리 누적이 이어짐

    func test_updateSpeed_시딩후_거리가_시딩값에서_누적() {
        // Given: 1.24km로 시딩
        sut.restoreStats(movingTimeSeconds: 90, movingDistanceKm: 1.24,
                         topSpeedKmh: 100, topLeanAngleDegrees: 0)

        // When: 72km/h(=20m/s)로 10초 주행 (스냅샷 2개, 10초 간격)
        let start = Date()
        _ = sut.updateSpeed(makeSnapshot(speedKmh: 72, at: start))
        _ = sut.updateSpeed(makeSnapshot(speedKmh: 72, at: start.addingTimeInterval(10)))

        // Then: 시딩 1.24km + 신규 0.2km = 1.44km (0부터 다시 세면 안 됨)
        XCTAssertEqual(sut.stats().movingDistanceKm, 1.44, accuracy: 0.01,
                       "거리는 시딩값에 이어서 누적되어야 합니다")
    }
}
