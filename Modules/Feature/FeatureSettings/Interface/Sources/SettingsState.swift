import Foundation
import CoreTrackingInterface
import CoreSensorsInterface

/// 설정 Feature의 State (MVI 패턴)
public struct SettingsState {
    public var thresholds: TrackingThresholds
    public var locationAuthorization: LocationAuthorizationStatus
    public var appVersion: String

    public init(
        thresholds: TrackingThresholds = TrackingPolicy.defaultThresholds,
        locationAuthorization: LocationAuthorizationStatus = .notDetermined,
        appVersion: String = ""
    ) {
        self.thresholds = thresholds
        self.locationAuthorization = locationAuthorization
        self.appVersion = appVersion
    }

    /// 조정값이 기본값과 다른지 — "기본값으로" 버튼 활성 여부.
    /// 슬라이더가 step 배수로 스냅하면서 기본값과 비트 단위로 달라질 수 있어 허용오차로 비교한다
    public var isCustomized: Bool {
        let base = TrackingPolicy.defaultThresholds
        func differs(_ lhs: Double, _ rhs: Double) -> Bool { abs(lhs - rhs) >= 0.001 }
        return differs(thresholds.accelerationKmhPerSec, base.accelerationKmhPerSec)
            || differs(thresholds.decelerationKmhPerSec, base.decelerationKmhPerSec)
            || differs(thresholds.minLeanAngleDegrees, base.minLeanAngleDegrees)
            || differs(thresholds.stopSpeedKmh, base.stopSpeedKmh)
    }
}
