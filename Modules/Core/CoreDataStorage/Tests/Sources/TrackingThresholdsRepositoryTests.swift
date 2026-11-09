//
//  TrackingThresholdsRepositoryTests.swift
//  CoreDataStorageTests
//

import XCTest
import CoreTrackingInterface
@testable import CoreDataStorage

final class TrackingThresholdsRepositoryTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var sut: TrackingThresholdsRepository!

    override func setUp() {
        super.setUp()
        // 표준 UserDefaults를 건드리지 않도록 테스트 전용 suite를 쓴다
        suiteName = "TrackingThresholdsRepositoryTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        sut = TrackingThresholdsRepository(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        sut = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeThresholds(
        acceleration: Double = 10.0,
        deceleration: Double = 11.0,
        lean: Double = 25.0,
        stopSpeed: Double = 2.0
    ) -> TrackingThresholds {
        TrackingThresholds(
            accelerationKmhPerSec: acceleration,
            decelerationKmhPerSec: deceleration,
            minLeanAngleDegrees: lean,
            stopSpeedKmh: stopSpeed
        )
    }

    func test_load_저장된값없으면_기본값반환() {
        // Given: 아무것도 저장하지 않은 상태

        // When
        let loaded = sut.load()

        // Then
        let expected = TrackingPolicy.defaultThresholds
        XCTAssertEqual(loaded.accelerationKmhPerSec, expected.accelerationKmhPerSec)
        XCTAssertEqual(loaded.decelerationKmhPerSec, expected.decelerationKmhPerSec)
        XCTAssertEqual(loaded.minLeanAngleDegrees, expected.minLeanAngleDegrees)
        XCTAssertEqual(loaded.stopSpeedKmh, expected.stopSpeedKmh)
    }

    func test_save_저장후_load하면_같은값반환() {
        // Given
        let thresholds = makeThresholds()

        // When
        sut.save(thresholds)
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded.accelerationKmhPerSec, 10.0)
        XCTAssertEqual(loaded.decelerationKmhPerSec, 11.0)
        XCTAssertEqual(loaded.minLeanAngleDegrees, 25.0)
        XCTAssertEqual(loaded.stopSpeedKmh, 2.0)
    }

    func test_save_덮어쓰면_마지막값반환() {
        // Given: 한 번 저장한 뒤
        sut.save(makeThresholds(lean: 25.0))

        // When: 다른 값으로 다시 저장
        sut.save(makeThresholds(lean: 40.0))

        // Then
        XCTAssertEqual(sut.load().minLeanAngleDegrees, 40.0)
    }
}
