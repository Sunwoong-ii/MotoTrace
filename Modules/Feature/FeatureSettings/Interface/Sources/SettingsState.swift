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

    /// 조정값이 기본값과 다른지 — "기본값으로" 버튼 활성 여부
    public var isCustomized: Bool {
        let base = TrackingPolicy.defaultThresholds
        return thresholds.accelerationKmhPerSec != base.accelerationKmhPerSec
            || thresholds.decelerationKmhPerSec != base.decelerationKmhPerSec
            || thresholds.minLeanAngleDegrees != base.minLeanAngleDegrees
            || thresholds.stopSpeedKmh != base.stopSpeedKmh
    }
}
