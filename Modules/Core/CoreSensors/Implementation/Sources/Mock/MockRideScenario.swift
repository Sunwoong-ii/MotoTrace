//  MockRideScenario.swift
//  CoreSensors
//
//  Created by Woong on 2026/07/08.
//

#if DEBUG
import Foundation

/// 시나리오 시간 t에서의 가상 주행 물리 상태
struct RideSample {
    let speedKmh: Double
    /// 진행 방향 (도, 0=북 시계방향) — Location.course와 동일 규약
    let headingDegrees: Double
    /// 린앵글 (도, 우회전 양수) — 코너 각속도에서 원심력 공식으로 유도
    let leanDegrees: Double
}

/// 스크립트된 가상 주행 시나리오 (105초 루프)
///
/// 속도·heading·린앵글을 하나의 물리 모델에서 유도해 서로 모순되지 않게 한다.
/// - 급가속/급감속: SpeedAnalyzer가 최근 5개(≈5초) 스냅샷 윈도우로 가속도를 계산하므로
///   순간 기울기가 아니라 "5초간 Δv ≥ 83.5 km/h"가 되도록 프로파일을 설계 (임계 16.7 km/h/s)
/// - 린앵글: 코너 yaw rate에서 lean = atan(v·ω/g)로 계산 — course 변화와 물리적으로 일치해야
///   LeanAngleAnalyzer의 gravity 투영 계산이 자연스럽게 동작 (피크 약 34.7° ≥ 임계 30°)
struct MockRideScenario {
    let loopDuration: TimeInterval = 105

    // 코너 공통 파라미터: 사다리꼴 각속도 프로파일 (1.5초 램프 + 3초 정점 + 1.5초 램프)
    // 정점 20°/s × 유효 4.5초 = 총 90° 회전, 70 km/h에서 lean ≈ 34.7°
    private let cornerDuration: TimeInterval = 6.0
    private let cornerRamp: TimeInterval = 1.5
    private let peakYawRateDegPerSec: Double = 20.0

    // 구간 경계 (초)
    private let rightCornerStart: TimeInterval = 40
    private let leftCornerStart: TimeInterval = 65

    func sample(at t: TimeInterval) -> RideSample {
        let clamped = max(0, min(t, loopDuration))
        return RideSample(
            speedKmh: speed(at: clamped),
            headingDegrees: heading(at: clamped),
            leanDegrees: lean(at: clamped)
        )
    }

    // MARK: - 속도 프로파일 (km/h)

    private func speed(at t: TimeInterval) -> Double {
        switch t {
        case ..<5: return 0                             // 정차 — 린앵글 영점 캘리브레이션 구간
        case ..<10: return lerp(0, 100, (t - 5) / 5)    // 급가속: +20 km/h/s → 이벤트 트리거
        case ..<35: return 100                          // 정속
        case ..<40: return lerp(100, 70, (t - 35) / 5)  // 완만 감속: -6 km/h/s → 이벤트 없음
        case ..<71: return 70                           // 코너 구간 포함 정속
        case ..<85: return lerp(70, 100, (t - 71) / 14) // 완만 가속: +2.1 km/h/s → 이벤트 없음
        case ..<90: return lerp(100, 0, (t - 85) / 5)   // 급제동: -20 km/h/s → 이벤트 트리거
        default: return 0                               // 정차 (< 3 km/h) 검증 구간
        }
    }

    // MARK: - Heading (도, 0=북 시계방향)

    private func heading(at t: TimeInterval) -> Double {
        if t < rightCornerStart { return 0 }
        if t < rightCornerStart + cornerDuration {
            return turnAngle(at: t - rightCornerStart)      // 우코너: 0° → 90°(동)
        }
        if t < leftCornerStart { return 90 }
        if t < leftCornerStart + cornerDuration {
            return 90 - turnAngle(at: t - leftCornerStart)  // 좌코너: 90° → 0°(북)
        }
        return 0
    }

    // MARK: - 린앵글 (도)

    private func lean(at t: TimeInterval) -> Double {
        let omegaDeg: Double
        if t >= rightCornerStart, t < rightCornerStart + cornerDuration {
            omegaDeg = yawRate(at: t - rightCornerStart)    // 우회전: ω 양수 → lean 양수
        } else if t >= leftCornerStart, t < leftCornerStart + cornerDuration {
            omegaDeg = -yawRate(at: t - leftCornerStart)    // 좌회전: ω 음수 → lean 음수
        } else {
            return 0
        }

        // 원심력 균형: lean = atan(v·ω / g)
        let v = speed(at: t) / 3.6
        let omegaRad = omegaDeg * .pi / 180
        return atan(v * omegaRad / 9.81) * 180 / .pi
    }

    // MARK: - 사다리꼴 각속도 프로파일

    /// 코너 진입 후 τ초 시점의 yaw rate (°/s, 항상 양수)
    private func yawRate(at tau: TimeInterval) -> Double {
        let p = peakYawRateDegPerSec
        let r = cornerRamp
        let constantEnd = cornerDuration - r
        switch tau {
        case ..<r: return p * tau / r
        case ..<constantEnd: return p
        case ..<cornerDuration: return p * (cornerDuration - tau) / r
        default: return 0
        }
    }

    /// 코너 진입 후 τ초까지의 누적 회전각 (도) — yawRate의 적분
    private func turnAngle(at tau: TimeInterval) -> Double {
        let p = peakYawRateDegPerSec
        let r = cornerRamp
        let constantEnd = cornerDuration - r
        switch tau {
        case ..<r:
            return p * tau * tau / (2 * r)
        case ..<constantEnd:
            return p * r / 2 + p * (tau - r)
        case ..<cornerDuration:
            let total = p * (cornerDuration - r)
            let remaining = cornerDuration - tau
            return total - p * remaining * remaining / (2 * r)
        default:
            return p * (cornerDuration - r)
        }
    }

    private func lerp(_ from: Double, _ to: Double, _ fraction: Double) -> Double {
        from + (to - from) * max(0, min(1, fraction))
    }
}
#endif
