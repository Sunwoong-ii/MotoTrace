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
            isCalibrated = true
            currentLeanAngleDegrees = 0
            return LeanAnalyzerResult()
        }

        // --- GPS heading 유효성 확인 ---
        let course = locationSnapshot.course
        guard course >= 0 else {
            // heading 없으면 이전 값 유지
            return LeanAnalyzerResult()
        }

        // --- 바이크 전진 축(f)을 device frame으로 변환 ---
        // GPS heading: 0=북, 시계방향 (도) → ENU world frame (East=x, North=y, Up=z)
        let hRad = course * .pi / 180.0
        let forwardWorld = (x: sin(hRad), y: cos(hRad), z: 0.0)

        // attitude quaternion: device→world. world→device는 켤레(w, -x, -y, -z)
        let q = (w: data.quaternionW, x: data.quaternionX,
                 y: data.quaternionY, z: data.quaternionZ)
        let qInv = (w: q.w, x: -q.x, y: -q.y, z: -q.z)
        let forwardDevice = normalize(rotate(q: qInv, v: forwardWorld))

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

        currentLeanAngleDegrees = leanDeg

        var result = LeanAnalyzerResult()
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

    // MARK: - Control

    func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double) {
        // 레거시 인터페이스 호환 — gravity 기반에서는 사용하지 않음
    }

    func setThresholds(_ thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }

    func handlePause() {
        // 일시정지 시 캘리브레이션 리셋 — 재개 후 첫 데이터로 재보정
        isCalibrated = false
        currentLeanAngleDegrees = 0
    }

    func reset() {
        isCalibrated = false
        calibrationGravity = (0, 0, -1)
        topLeanAngleDegrees = 0
        currentLeanAngleDegrees = 0
    }

    // MARK: - Getters

    func currentLeanAngle() -> Double { currentLeanAngleDegrees }
    func topLeanAngle() -> Double { topLeanAngleDegrees }
}
