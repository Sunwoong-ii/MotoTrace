//
//  TrackingAnalyzerThresholdsTests.swift
//  CoreTrackingTests
//

import XCTest
import CoreTrackingInterface
@testable import CoreTracking

/// setThresholds로 바꾼 기준이 실제 이벤트 감지에 반영되는지 검증한다.
/// (설정 화면에서 조정한 값이 주행 분석에 먹히는지를 보장하는 테스트)
final class TrackingAnalyzerThresholdsTests: XCTestCase {

    private var sut: TrackingAnalyzer!

    override func setUp() {
        super.setUp()
        sut = TrackingAnalyzer(thresholds: TrackingPolicy.defaultThresholds)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeMotion(gx: Double, gy: Double, gz: Double,
                            qw: Double = 1, qx: Double = 0) -> MotionSnapshot {
        MotionSnapshot(
            timestamp: Date(),
            rollDegrees: 0, pitchDegrees: 0,
            userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0,
            gravityX: gx, gravityY: gy, gravityZ: gz,
            quaternionW: qw, quaternionX: qx, quaternionY: 0, quaternionZ: 0
        )
    }

    private func makeLocation(speedKmh: Double = 60) -> LocationSnapshot {
        LocationSnapshot(
            timestamp: Date(),
            speedKmh: speedKmh,
            location: Location(latitude: 37.0, longitude: 127.0, timestamp: Date()),
            course: 0
        )
    }

    /// 우측 기울기 degrees°에 해당하는 스냅샷 (전진축=북 기준, 0=직립)
    private func leanMotion(degrees: Double) -> MotionSnapshot {
        let rad = degrees * .pi / 180.0
        let half = rad / 2.0
        return makeMotion(gx: 0, gy: -sin(rad), gz: -cos(rad), qw: cos(half), qx: sin(half))
    }

    /// 영점을 잡은 뒤 목표 각도까지 기울였다가 복귀시켜, 코너에서 방출된 이벤트를 모은다
    private func leanEvents(peak: Double) -> [TrackingEvent] {
        // updateAttitude는 직전 위치(course·속도)가 있어야 린앵글을 계산한다
        sut.updateLocation(makeLocation())
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1))
        var events: [TrackingEvent] = []
        for degrees in [peak, 0.0] {
            sut.updateLocation(makeLocation())
            if let event = sut.updateAttitude(leanMotion(degrees: degrees)).event {
                events.append(event)
            }
        }
        return events
    }

    // MARK: - 뱅킹각 기준

    func test_setThresholds_기준보다_낮은_기울기면_이벤트없음() {
        // Given: 뱅킹각 기준을 45°로 올린다
        sut.setThresholds(thresholds(minLeanAngle: 45))

        // When: 35° 코너를 돈다
        let events = leanEvents(peak: 35)

        // Then
        XCTAssertTrue(events.isEmpty, "기준(45°)보다 낮은 35° 코너는 이벤트가 없어야 합니다")
    }

    func test_setThresholds_기준을_낮추면_같은_기울기에서_이벤트발생() {
        // Given: 같은 35° 코너라도 기준을 20°로 낮추면
        sut.setThresholds(thresholds(minLeanAngle: 20))

        // When
        let events = leanEvents(peak: 35)

        // Then
        XCTAssertEqual(events.count, 1, "기준(20°)을 넘는 35° 코너는 이벤트가 1건 나와야 합니다")
        XCTAssertEqual(abs(events.first?.leanAngle ?? 0), 35, accuracy: 1.0)
    }

    // MARK: - 급가속 기준

    func test_setThresholds_급가속_기준을_올리면_같은_가속에서_이벤트없음() {
        // Given: 1초에 20km/h 가속하는 입력
        let accelerationPerSecond = 20.0

        // When: 기준을 그보다 높은 30으로 올린다
        sut.setThresholds(thresholds(acceleration: 30))
        let events = speedEvents(accelerationPerSecond: accelerationPerSecond)

        // Then
        XCTAssertFalse(
            events.contains { $0.type == .rapidAcceleration },
            "기준(30)보다 완만한 20km/h/s 가속은 급가속이 아니어야 합니다"
        )
    }

    // MARK: - Helpers (speed)

    private func thresholds(
        acceleration: Double = 16.7,
        deceleration: Double = 16.7,
        minLeanAngle: Double = 30.0,
        stopSpeed: Double = 3.0
    ) -> TrackingThresholds {
        TrackingThresholds(
            accelerationKmhPerSec: acceleration,
            decelerationKmhPerSec: deceleration,
            minLeanAngleDegrees: minLeanAngle,
            stopSpeedKmh: stopSpeed
        )
    }

    /// 1초 간격으로 가속하는 위치 스냅샷을 흘려 속도 이벤트를 모은다
    private func speedEvents(accelerationPerSecond: Double) -> [TrackingEvent] {
        var events: [TrackingEvent] = []
        let start = Date()
        for step in 0...4 {
            let snapshot = LocationSnapshot(
                timestamp: start.addingTimeInterval(Double(step)),
                speedKmh: Double(step) * accelerationPerSecond,
                location: Location(latitude: 37.0, longitude: 127.0, timestamp: start),
                course: 0
            )
            if let event = sut.updateSpeed(snapshot).event {
                events.append(event)
            }
        }
        return events
    }
}
