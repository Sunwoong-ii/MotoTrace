//  RideSessionRuntime.swift
//  FeatureTour
//
//  Created by Woong on 2026/07/20.
//

import UIKit

/// 주행 세션이 살아있는 동안 유지해야 하는 기기 런타임 상태를 관장한다.
/// 지금은 화면 자동 잠금(idle timer)만 다루지만, 같은 라이프사이클(주행 중 유지·종료 시 해제)을
/// 공유하는 관심사가 늘면 구현체 한 곳(apply())에 모은다.
@MainActor
protocol RideSessionRuntime: AnyObject {
    /// 주행 세션 활성 여부를 반영한다. active면 화면 잠금을 끄고, 아니면 시스템에 다시 위임한다.
    func setSessionActive(_ active: Bool)
}

/// UIKit 기반 실 구현.
/// isIdleTimerDisabled는 iOS가 백그라운드 진입 시 리셋하므로, willEnterForeground에서
/// 현재 세션 상태로 재적용한다(self-heal) — 호출자(Store)는 이 시스템 특성을 몰라도 된다.
@MainActor
final class SystemRideSessionRuntime: NSObject, RideSessionRuntime {
    private var isSessionActive = false

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setSessionActive(_ active: Bool) {
        isSessionActive = active
        apply()
    }

    @objc private func handleWillEnterForeground() {
        apply()
    }

    private func apply() {
        UIApplication.shared.isIdleTimerDisabled = isSessionActive
        // 화면 밝기 부스트·근접센서 off 등 같은 라이프사이클 관심사가 생기면 여기에 추가한다
    }
}
