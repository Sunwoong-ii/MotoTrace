//  MockAttitudeFactory.swift
//  CoreSensors
//
//  Created by Woong on 2026/07/08.
//

#if DEBUG
import Foundation

/// (heading, lean, pitch) → CMDeviceMotion(xTrueNorthZVertical, NWU 프레임)과 동일 규약의
/// attitude quaternion + gravity 벡터 생성.
///
/// gravity를 별도로 만들지 않고 quaternion에서 유도하는 이유:
/// LeanAngleAnalyzer가 gravity와 quaternion을 조합해 린앵글을 계산하므로
/// 두 값이 조금만 어긋나도 결과가 왜곡된다. 구성상(by construction) 일관성을 보장하면
/// 분석기가 시나리오의 lean·pitch 값을 기하학적으로 정확히 복원한다.
enum MockAttitudeFactory {
    struct Attitude {
        let quaternionW: Double
        let quaternionX: Double
        let quaternionY: Double
        let quaternionZ: Double
        let gravityX: Double
        let gravityY: Double
        let gravityZ: Double
    }

    static func attitude(headingDegrees: Double, leanDegrees: Double, pitchDegrees: Double = 0) -> Attitude {
        let h = headingDegrees * .pi / 180
        let lean = leanDegrees * .pi / 180
        let slope = pitchDegrees * .pi / 180

        // yaw: 월드 z축 기준 -h 회전 — device +x(진북 정렬)가 heading 방향을 향하게 함
        // NWU에서 +z 회전은 북→서 방향이므로 시계방향 heading은 -h
        let qYaw = Quaternion(w: cos(h / 2), x: 0, y: 0, z: -sin(h / 2))

        // 바이크 전진축 (월드, NWU): heading h → (cos h, -sin h, 0)
        let forward = Vector3(x: cos(h), y: -sin(h), z: 0)

        // pitch(경사): 측면축 (-sin h, -cos h, 0) 기준 회전 —
        // 이 축 방향이어야 양수 slope가 nose-up(오르막)이 됨 (h=0에서 축=동쪽, 북→위 회전)
        let lateral = Vector3(x: -sin(h), y: -cos(h), z: 0)
        let halfSlope = slope / 2
        let qPitch = Quaternion(
            w: cos(halfSlope),
            x: sin(halfSlope) * lateral.x,
            y: sin(halfSlope) * lateral.y,
            z: sin(halfSlope) * lateral.z
        )

        // lean: 경사 반영된 전진축 기준 -lean 회전.
        // 시나리오는 경사·린을 겹치지 않게 배치하지만, 겹쳐도 물리적으로 일관되도록
        // 기울어진 도로 방향 축을 사용. 부호는 LeanAngleAnalyzer의
        // atan2(dot(g0×g1, f), ...) 규약과 일치하도록 고정 — 단위 테스트로 핀 다운
        let forwardInclined = qPitch.rotate(forward)
        let half = -lean / 2
        let qLean = Quaternion(
            w: cos(half),
            x: sin(half) * forwardInclined.x,
            y: sin(half) * forwardInclined.y,
            z: sin(half) * forwardInclined.z
        )

        // 합성: yaw → pitch → lean 순 적용 (모두 월드 프레임 기준 회전)
        let q = qLean.multiplied(by: qPitch).multiplied(by: qYaw)

        // gravity(device frame) = q⁻¹로 월드 중력 (0,0,-1)을 회전
        let gravity = q.conjugate.rotate(Vector3(x: 0, y: 0, z: -1))

        return Attitude(
            quaternionW: q.w,
            quaternionX: q.x,
            quaternionY: q.y,
            quaternionZ: q.z,
            gravityX: gravity.x,
            gravityY: gravity.y,
            gravityZ: gravity.z
        )
    }
}

// MARK: - 내부 수학 타입

private struct Vector3 {
    let x: Double
    let y: Double
    let z: Double
}

private struct Quaternion {
    let w: Double
    let x: Double
    let y: Double
    let z: Double

    var conjugate: Quaternion {
        Quaternion(w: w, x: -x, y: -y, z: -z)
    }

    /// Hamilton product: self ⊗ other (other 회전을 먼저 적용)
    func multiplied(by other: Quaternion) -> Quaternion {
        Quaternion(
            w: w * other.w - x * other.x - y * other.y - z * other.z,
            x: w * other.x + x * other.w + y * other.z - z * other.y,
            y: w * other.y - x * other.z + y * other.w + z * other.x,
            z: w * other.z + x * other.y - y * other.x + z * other.w
        )
    }

    /// 벡터 회전 (q ⊗ v ⊗ q⁻¹) — LeanAngleAnalyzer의 rotate와 동일 수식
    func rotate(_ v: Vector3) -> Vector3 {
        let tx = 2.0 * (y * v.z - z * v.y)
        let ty = 2.0 * (z * v.x - x * v.z)
        let tz = 2.0 * (x * v.y - y * v.x)
        return Vector3(
            x: v.x + w * tx + y * tz - z * ty,
            y: v.y + w * ty + z * tx - x * tz,
            z: v.z + w * tz + x * ty - y * tx
        )
    }
}
#endif
