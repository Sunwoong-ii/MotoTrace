//  MockRideScenarioTests.swift
//  CoreSensorsTests
//
//  Created by Woong on 2026/07/08.
//

#if DEBUG
import XCTest
@testable import CoreSensors

/// 시나리오가 분석기 임계값 계약을 지키는지 검증 —
/// Mock 센서의 존재 이유가 "이벤트가 반드시 발화하는 데이터"이므로 회귀 방지가 핵심
final class MockRideScenarioTests: XCTestCase {
    private let scenario = MockRideScenario()

    // TrackingPolicy 기본 임계값 (README/CoreTracking 기준)
    private let accelerationThreshold = 16.7
    private let leanAngleThreshold = 30.0

    // MARK: - 급가속/급감속

    func test_시나리오_급가속구간이_5초윈도우_임계값을_초과하는지() {
        // Given: SpeedAnalyzer는 순간 기울기가 아니라 최근 5개(1Hz ≈ 5초) 스냅샷
        // 윈도우의 (현재속도 - first속도)/Δt 로 가속도를 계산함

        // When
        let maxAccel = fiveSecondWindowAccelerations().max() ?? 0

        // Then
        XCTAssertGreaterThanOrEqual(maxAccel, accelerationThreshold)
    }

    func test_시나리오_급감속구간이_5초윈도우_임계값을_초과하는지() {
        // When
        let minAccel = fiveSecondWindowAccelerations().min() ?? 0

        // Then
        XCTAssertLessThanOrEqual(minAccel, -accelerationThreshold)
    }

    // MARK: - 뱅킹각

    func test_시나리오_좌우코너_뱅킹각이_30도이상인지() {
        // Given
        var maxLean = 0.0
        var minLean = 0.0

        // When: 0.1초 간격으로 한 루프 순회
        for t in stride(from: 0.0, to: scenario.loopDuration, by: 0.1) {
            let lean = scenario.sample(at: t).leanDegrees
            maxLean = max(maxLean, lean)
            minLean = min(minLean, lean)
        }

        // Then: 우코너 양수, 좌코너 음수 피크 모두 임계값 초과
        XCTAssertGreaterThanOrEqual(maxLean, leanAngleThreshold)
        XCTAssertLessThanOrEqual(minLean, -leanAngleThreshold)
    }

    // MARK: - gravity/quaternion 일관성

    func test_모션_gravity와_quaternion이_일관된_단위벡터인지() {
        for t in stride(from: 0.0, to: scenario.loopDuration, by: 0.5) {
            // Given
            let sample = scenario.sample(at: t)

            // When
            let attitude = MockAttitudeFactory.attitude(
                headingDegrees: sample.headingDegrees,
                leanDegrees: sample.leanDegrees,
                pitchDegrees: sample.pitchDegrees
            )

            // Then: 둘 다 단위 크기 — CMDeviceMotion 규약과 동일
            let gravityNorm = (attitude.gravityX * attitude.gravityX
                + attitude.gravityY * attitude.gravityY
                + attitude.gravityZ * attitude.gravityZ).squareRoot()
            let quaternionNorm = (attitude.quaternionW * attitude.quaternionW
                + attitude.quaternionX * attitude.quaternionX
                + attitude.quaternionY * attitude.quaternionY
                + attitude.quaternionZ * attitude.quaternionZ).squareRoot()
            XCTAssertEqual(gravityNorm, 1.0, accuracy: 1e-9, "t=\(t)")
            XCTAssertEqual(quaternionNorm, 1.0, accuracy: 1e-9, "t=\(t)")

            // 직립·평지 구간에서는 gravity가 정확히 아래(0,0,-1)를 향해야 캘리브레이션이 자연스러움
            if sample.leanDegrees == 0 && sample.pitchDegrees == 0 {
                XCTAssertEqual(attitude.gravityX, 0, accuracy: 1e-9, "t=\(t)")
                XCTAssertEqual(attitude.gravityY, 0, accuracy: 1e-9, "t=\(t)")
                XCTAssertEqual(attitude.gravityZ, -1, accuracy: 1e-9, "t=\(t)")
            }
        }
    }

    // MARK: - 린앵글 복원

    func test_린앵글_분석기_투영수식으로_시나리오_린앵글이_부호까지_복원되는지() {
        // Given: t=0(정차·직립) 자세로 영점 캘리브레이션 —
        // LeanAngleAnalyzer가 첫 모션의 gravity를 영점으로 잡는 동작과 동일
        let calibration = MockAttitudeFactory.attitude(headingDegrees: 0, leanDegrees: 0)
        let calibrationGravity = (
            x: calibration.gravityX, y: calibration.gravityY, z: calibration.gravityZ
        )

        // When/Then: 우코너 정점(t=43, +34.7°)과 좌코너 정점(t=68, -34.7°)에서
        // 분석기 수식이 시나리오 lean을 부호까지 복원해야 함 —
        // 이 부호 규약을 여기서 고정해 gravity 방식 픽스처 깨짐(백로그 이력) 재발 방지
        for t in [43.0, 68.0] {
            let sample = scenario.sample(at: t)
            let attitude = MockAttitudeFactory.attitude(
                headingDegrees: sample.headingDegrees,
                leanDegrees: sample.leanDegrees,
                pitchDegrees: sample.pitchDegrees
            )
            let recovered = recoverLeanAngle(
                calibrationGravity: calibrationGravity,
                attitude: attitude,
                courseDegrees: sample.headingDegrees
            )
            XCTAssertGreaterThan(abs(sample.leanDegrees), leanAngleThreshold, "t=\(t) 정점이 임계값 미만")
            XCTAssertEqual(recovered, sample.leanDegrees, accuracy: 1.0, "t=\(t)")
        }
    }

    // MARK: - 경사각 복원

    func test_경사각_분석기_차체축_수식으로_시나리오_경사가_부호까지_복원되는지() {
        // Given: 평지 주행 시점(t=6)의 수평 forward를 차체 축으로 캡처 —
        // LeanAngleAnalyzer가 주행 시작 직후 평지에서 차체 축을 캡처하는 동작과 동일
        let flat = scenario.sample(at: 6)
        let flatAttitude = MockAttitudeFactory.attitude(
            headingDegrees: flat.headingDegrees,
            leanDegrees: flat.leanDegrees,
            pitchDegrees: flat.pitchDegrees
        )
        let bodyForward = horizontalForwardDevice(
            attitude: flatAttitude, courseDegrees: flat.headingDegrees
        )

        // When/Then: 오르막 정점(t=22, +8°)과 내리막 정점(t=55, -6°)에서
        // 분석기의 -asin(dot(g, 차체축)) 수식이 시나리오 경사를 부호까지 복원해야 함
        for t in [22.0, 55.0] {
            let sample = scenario.sample(at: t)
            let attitude = MockAttitudeFactory.attitude(
                headingDegrees: sample.headingDegrees,
                leanDegrees: sample.leanDegrees,
                pitchDegrees: sample.pitchDegrees
            )
            let g: Vec = (x: attitude.gravityX, y: attitude.gravityY, z: attitude.gravityZ)
            let recovered = -asin(max(-1.0, min(1.0, dot(g, bodyForward)))) * 180 / .pi
            XCTAssertNotEqual(sample.pitchDegrees, 0, "t=\(t) 정점이 경사 구간이 아님")
            XCTAssertEqual(recovered, sample.pitchDegrees, accuracy: 0.5, "t=\(t)")
        }
    }

    // MARK: - 루프 연속성

    func test_루프경계에서_속도와_heading이_연속인지() {
        // Given
        let loopStart = scenario.sample(at: 0)
        let loopEnd = scenario.sample(at: scenario.loopDuration - 0.001)

        // Then: 경계에서 값이 튀면 지도 경로·통계가 매 루프마다 왜곡됨
        XCTAssertEqual(loopStart.speedKmh, loopEnd.speedKmh, accuracy: 1.0)
        XCTAssertEqual(
            loopStart.headingDegrees.truncatingRemainder(dividingBy: 360),
            loopEnd.headingDegrees.truncatingRemainder(dividingBy: 360),
            accuracy: 1.0
        )
        XCTAssertEqual(loopStart.leanDegrees, loopEnd.leanDegrees, accuracy: 1.0)
        XCTAssertEqual(loopStart.pitchDegrees, loopEnd.pitchDegrees, accuracy: 1.0)
    }

    // MARK: - Helpers

    /// SpeedAnalyzer의 윈도우 가속도 미러링: 1Hz 샘플링, (현재 - 5개 전)/5초
    private func fiveSecondWindowAccelerations() -> [Double] {
        var speeds: [Double] = []
        for t in stride(from: 0.0, to: scenario.loopDuration, by: 1.0) {
            speeds.append(scenario.sample(at: t).speedKmh)
        }
        var accelerations: [Double] = []
        for i in 5..<speeds.count {
            accelerations.append((speeds[i] - speeds[i - 5]) / 5.0)
        }
        return accelerations
    }

    private typealias Vec = (x: Double, y: Double, z: Double)

    /// LeanAngleAnalyzer의 수평 forward → device frame 변환 미러링 —
    /// 린앵글 투영 축이자 경사각용 차체 축 캡처(평지 시점)와 동일한 계산
    private func horizontalForwardDevice(
        attitude: MockAttitudeFactory.Attitude,
        courseDegrees: Double
    ) -> Vec {
        let hRad = courseDegrees * .pi / 180
        let forwardWorld: Vec = (x: cos(hRad), y: -sin(hRad), z: 0)

        let q = (w: attitude.quaternionW, x: attitude.quaternionX,
                 y: attitude.quaternionY, z: attitude.quaternionZ)
        let qInv = (w: q.w, x: -q.x, y: -q.y, z: -q.z)
        return normalize(rotate(q: qInv, v: forwardWorld))
    }

    /// LeanAngleAnalyzer.updateAttitude의 투영·atan2 수식 미러링
    /// 원본: Modules/Core/CoreTracking/Implementation/Sources/SubAnalyzer/LeanAngleAnalyzer.swift
    /// (CoreSensorsTests는 CoreTracking에 의존할 수 없어 수식을 복제해 검증)
    private func recoverLeanAngle(
        calibrationGravity g0: Vec,
        attitude: MockAttitudeFactory.Attitude,
        courseDegrees: Double
    ) -> Double {
        let forwardDevice = horizontalForwardDevice(attitude: attitude, courseDegrees: courseDegrees)

        let g1: Vec = (x: attitude.gravityX, y: attitude.gravityY, z: attitude.gravityZ)

        let g0d = dot(g0, forwardDevice)
        let g0Perp = normalize((
            x: g0.x - g0d * forwardDevice.x,
            y: g0.y - g0d * forwardDevice.y,
            z: g0.z - g0d * forwardDevice.z
        ))
        let g1d = dot(g1, forwardDevice)
        let g1Perp = normalize((
            x: g1.x - g1d * forwardDevice.x,
            y: g1.y - g1d * forwardDevice.y,
            z: g1.z - g1d * forwardDevice.z
        ))

        let c = cross(g0Perp, g1Perp)
        let sinA = dot(c, forwardDevice)
        let cosA = dot(g0Perp, g1Perp)
        return atan2(sinA, cosA) * 180 / .pi
    }

    private func dot(_ a: Vec, _ b: Vec) -> Double {
        a.x * b.x + a.y * b.y + a.z * b.z
    }

    private func cross(_ a: Vec, _ b: Vec) -> Vec {
        (x: a.y * b.z - a.z * b.y, y: a.z * b.x - a.x * b.z, z: a.x * b.y - a.y * b.x)
    }

    private func normalize(_ v: Vec) -> Vec {
        let len = (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
        guard len > 1e-9 else { return v }
        return (v.x / len, v.y / len, v.z / len)
    }

    private func rotate(q: (w: Double, x: Double, y: Double, z: Double), v: Vec) -> Vec {
        let t: Vec = (
            x: 2.0 * (q.y * v.z - q.z * v.y),
            y: 2.0 * (q.z * v.x - q.x * v.z),
            z: 2.0 * (q.x * v.y - q.y * v.x)
        )
        return (
            x: v.x + q.w * t.x + q.y * t.z - q.z * t.y,
            y: v.y + q.w * t.y + q.z * t.x - q.x * t.z,
            z: v.z + q.w * t.z + q.x * t.y - q.y * t.x
        )
    }
}
#endif
