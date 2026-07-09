//  LeanAngleAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface

// MARK: - SIMD helpers (internal)

private func dot(_ a: (x: Double, y: Double, z: Double),
                 _ b: (x: Double, y: Double, z: Double)) -> Double {
    a.x * b.x + a.y * b.y + a.z * b.z
}

private func cross(_ a: (x: Double, y: Double, z: Double),
                   _ b: (x: Double, y: Double, z: Double)) -> (x: Double, y: Double, z: Double) {
    (
        x: a.y * b.z - a.z * b.y,
        y: a.z * b.x - a.x * b.z,
        z: a.x * b.y - a.y * b.x
    )
}

private func normalize(_ v: (x: Double, y: Double, z: Double)) -> (x: Double, y: Double, z: Double) {
    let len = (v.x*v.x + v.y*v.y + v.z*v.z).squareRoot()
    guard len > 1e-9 else { return v }
    return (v.x/len, v.y/len, v.z/len)
}

/// 쿼터니언 q 로 벡터 v 를 회전 (q * v * q^-1)
private func rotate(q: (w: Double, x: Double, y: Double, z: Double),
                    v: (x: Double, y: Double, z: Double)) -> (x: Double, y: Double, z: Double) {
    let t = (
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

// MARK: - LeanAnalyzer

final class LeanAnalyzer {
    private var thresholds: TrackingThresholds

    // 캘리브레이션 시점의 중력 벡터 (device frame)
    private var calibrationGravity: (x: Double, y: Double, z: Double) = (0, 0, -1)
    private var isCalibrated = false

    // 캘리브레이션 시점의 attitude 오일러 각 — course 미확보 시 폴백 계산용
    private var calibrationRollDegrees: Double = 0
    private var calibrationPitchDegrees: Double = 0

    // 마지막 유효 course로 계산한 바이크 전진 축 (device frame)
    // 폰이 마운트에 고정돼 있으면 정지 등으로 course가 -1이 돼도 이 축은 유지되므로 재사용한다
    private var lastForwardDevice: (x: Double, y: Double, z: Double)?

    private var topLeanAngleDegrees: Double = 0
    private var currentLeanAngleDegrees: Double = 0

    init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }

    // MARK: - Main update

    /// - Parameters:
    ///   - data: 모션 스냅샷 (gravity + quaternion 포함)
    ///   - locationSnapshot: 최신 위치 스냅샷 (GPS heading 포함)
    func updateAttitude(_ data: MotionSnapshot, locationSnapshot: LocationSnapshot) -> LeanAnalyzerResult {
        let g = (x: data.gravityX, y: data.gravityY, z: data.gravityZ)

        // --- 캘리브레이션 ---
        if !isCalibrated {
            calibrationGravity = g
            calibrationRollDegrees = data.rollDegrees
            calibrationPitchDegrees = data.pitchDegrees
            isCalibrated = true
            currentLeanAngleDegrees = 0
            return LeanAnalyzerResult()
        }

        // --- 바이크 전진 축(f) 결정 ---
        // 정지 상태에서는 GPS course가 -1이라 전진 축을 새로 못 구한다.
        // 마운트 고정 전제이므로 마지막 유효 축을 재사용하고,
        // 한 번도 course가 없었으면(주행 시작 전) 오일러 델타로 폴백한다.
        let course = locationSnapshot.course
        let forwardDevice: (x: Double, y: Double, z: Double)
        if course >= 0 {
            // GPS heading: 0=북, 시계방향 (도)
            // CMDeviceMotion xTrueNorthZVertical 프레임 = NWU (x=진북, y=서, z=위)
            // heading h → forwardWorld = (cos(h), -sin(h), 0)
            //   h=0° (북): (1, 0, 0) = +x ✓
            //   h=90° (동): (0, -1, 0) = -y ✓  (동 = 서의 반대)
            //   h=270° (서): (0, 1, 0) = +y ✓
            let hRad = course * .pi / 180.0
            let forwardWorld = (x: cos(hRad), y: -sin(hRad), z: 0.0)

            // attitude quaternion: device→world. world→device는 켤레(w, -x, -y, -z)
            let q = (w: data.quaternionW, x: data.quaternionX,
                     y: data.quaternionY, z: data.quaternionZ)
            let qInv = (w: q.w, x: -q.x, y: -q.y, z: -q.z)
            forwardDevice = normalize(rotate(q: qInv, v: forwardWorld))
            lastForwardDevice = forwardDevice
        } else if let cached = lastForwardDevice {
            forwardDevice = cached
        } else {
            // 경사 분리가 안 되는 근사값 — course 확보 즉시 정식 계산으로 전환된다
            let leanDeg = normalizeDegrees(data.rollDegrees - calibrationRollDegrees)
            let pitchDeg = normalizeDegrees(data.pitchDegrees - calibrationPitchDegrees)
            return makeResult(leanDeg: leanDeg, pitchDeg: pitchDeg, locationSnapshot: locationSnapshot)
        }

        // --- 린 축 투영: g0/g1을 전진 축(f)에 수직인 평면으로 투영 ---
        // 이 투영이 오르막/내리막 성분을 자동으로 제거
        let g0 = calibrationGravity
        let g1 = g

        let g0d = dot(g0, forwardDevice)
        let g0_perp = normalize((
            x: g0.x - g0d * forwardDevice.x,
            y: g0.y - g0d * forwardDevice.y,
            z: g0.z - g0d * forwardDevice.z
        ))

        let g1d = dot(g1, forwardDevice)
        let g1_perp = normalize((
            x: g1.x - g1d * forwardDevice.x,
            y: g1.y - g1d * forwardDevice.y,
            z: g1.z - g1d * forwardDevice.z
        ))

        // --- atan2 로 정확한 부호 포함 각도 계산 ---
        let c = cross(g0_perp, g1_perp)
        let sinA = dot(c, forwardDevice)   // 부호: 오른쪽=양수
        let cosA = dot(g0_perp, g1_perp)
        let leanRad = atan2(sinA, cosA)
        let leanDeg = leanRad * 180.0 / .pi

        // --- 경사각: 전진 방향으로의 중력 투영 → asin ---
        // g1d = dot(g1, forwardDevice): 오르막이면 양수, 내리막이면 음수
        // g1은 단위 벡터이므로 asin(g1d) = 경사각 (도)
        let pitchDeg = asin(max(-1.0, min(1.0, g1d))) * 180.0 / .pi

        return makeResult(leanDeg: leanDeg, pitchDeg: pitchDeg, locationSnapshot: locationSnapshot)
    }

    // MARK: - Result

    private func makeResult(leanDeg: Double, pitchDeg: Double, locationSnapshot: LocationSnapshot) -> LeanAnalyzerResult {
        currentLeanAngleDegrees = leanDeg

        var result = LeanAnalyzerResult(pitchAngle: pitchDeg)
        // 정지 중 폰 조작(거치 해제, 손 테스트 등)으로 생긴 기울기가
        // 투어 기록(이벤트·최대 린앵글)을 오염시키지 않도록 주행 속도일 때만 기록한다
        guard locationSnapshot.speedKmh >= thresholds.stopSpeedKmh else {
            return result
        }
        if abs(leanDeg) > abs(topLeanAngleDegrees) {
            topLeanAngleDegrees = leanDeg
            result.maxLeanAngleUpdated = leanDeg
        }
        if abs(leanDeg) >= thresholds.minLeanAngleDegrees {
            result.event = TrackingEvent(
                startSpeedKmh: locationSnapshot.speedKmh,
                location: locationSnapshot.location,
                leanAngle: leanDeg
            )
        }

        return result
    }

    private func normalizeDegrees(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 } else if d < -180 { d += 360 }
        return d
    }

    // MARK: - Control

    func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double) {
        // 레거시 인터페이스 호환 — gravity 기반에서는 사용하지 않음
    }

    func setThresholds(_ thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }

    func handlePause() {
        // 일시정지 시 캘리브레이션 리셋 — 재개 후 첫 데이터로 재보정
        // 정지 중 재거치 가능성이 있으므로 전진 축 캐시도 무효화
        isCalibrated = false
        currentLeanAngleDegrees = 0
        lastForwardDevice = nil
    }

    func reset() {
        isCalibrated = false
        calibrationGravity = (0, 0, -1)
        calibrationRollDegrees = 0
        calibrationPitchDegrees = 0
        lastForwardDevice = nil
        topLeanAngleDegrees = 0
        currentLeanAngleDegrees = 0
    }

    // MARK: - Getters

    func currentLeanAngle() -> Double { currentLeanAngleDegrees }
    func topLeanAngle() -> Double { topLeanAngleDegrees }
}
