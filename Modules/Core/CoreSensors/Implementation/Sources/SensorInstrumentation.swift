//  SensorInstrumentation.swift
//  MotoTrace
//
//  Created by Woong on 2026/07/10.
//

import Foundation
import os
import UIKit

#if DEBUG
/// 백그라운드에서 location/motion 콜백이 끊기지 않는지 실기기에서 검증하기 위한 계측 로깅.
/// 주행 후 Mac에서 추출한다:
///   log collect --device --last 2h
///   log show system_logs.logarchive --predicate 'subsystem == "com.woong.MotoTrace.sensors"' --info
enum SensorInstrumentation {
    static let subsystem = "com.woong.MotoTrace.sensors"
}
#endif

/// CoreSensorsService의 계측 접점을 모은 파사드 — 진단 코드가 센서 로직에
/// 흩어지지 않도록 서비스 본체에는 프로퍼티 하나·호출 두 줄만 남긴다.
/// DEBUG 빌드 전용 — 실기기 검증은 Xcode로 설치한 Debug 빌드로 하므로 홈 화면 실행에서도
/// 동작하고, Release 빌드에서는 빈 구현으로 대체돼 5Hz 로깅 비용이 사라진다.
/// (launch argument 게이트는 홈 화면 실행에 인자가 안 붙어 실주행 테스트에서 꺼지므로 부적합)
final class CoreSensorsInstrumentation {
    #if DEBUG
    // location은 1Hz 명목 주기라 지터 오탐을 피해 2초, motion(5Hz)은 1초(콜백 5회 유실)를 공백 기준으로 본다
    private let location = SensorStreamInstrumentation(category: "location", gapThreshold: 2.0)
    private let motion = SensorStreamInstrumentation(category: "motion", gapThreshold: 1.0)
    // 참조 없이 보유만 한다 — init에서 등록한 라이프사이클 관찰을 살려두는 것이 목적
    private let lifecycle = AppLifecycleInstrumentation()

    func recordLocationCallback(speedKmh: Double, horizontalAccuracy: Double) {
        location.recordCallback(
            detail: String(format: "speed=%.1fkm/h acc=%.0fm", speedKmh, horizontalAccuracy)
        )
    }

    /// roll/yaw를 함께 기록 — 화면 잠금 상태에서 xTrueNorthZVertical 프레임의 yaw 드리프트 여부 확인용
    func recordMotionCallback(rollDegrees: Double, yawDegrees: Double) {
        motion.recordCallback(
            detail: String(format: "roll=%.1f yaw=%.1f", rollDegrees, yawDegrees)
        )
    }
    #else
    func recordLocationCallback(speedKmh: Double, horizontalAccuracy: Double) {}
    func recordMotionCallback(rollDegrees: Double, yawDegrees: Double) {}
    #endif
}

#if DEBUG
/// 센서 콜백 수신 계측 — 콜백마다 수신 로그를 남기고, 직전 수신과의 간격이
/// 임계값을 넘으면 경고 로그로 표시해 백그라운드 진입/화면 잠금 시점과 대조할 수 있게 한다.
/// 5Hz 모션 콜백 경로에서 호출되므로 unfair lock + os Logger만 사용해 오버헤드를 최소화한다.
/// gap 측정은 의도적으로 wall clock(Date) 기준 — 모노토닉 클록은 딥슬립 중 멈춰서
/// 서스펜션으로 생긴 공백(이 계측의 핵심 관심사)을 감지하지 못한다.
final class SensorStreamInstrumentation: Sendable {
    private let logger: Logger
    private let gapThreshold: TimeInterval
    private let lastCallbackAt = OSAllocatedUnfairLock<Date?>(initialState: nil)

    init(category: String, gapThreshold: TimeInterval) {
        self.logger = Logger(subsystem: SensorInstrumentation.subsystem, category: category)
        self.gapThreshold = gapThreshold
    }

    /// 콜백 수신을 기록한다. detail은 값 튐 확인용 짧은 상태 문자열 (좌표는 프라이버시상 남기지 않는다)
    /// 반환값은 임계값을 넘은 공백 시간 — OSLog 출력은 테스트로 검증할 수 없어 gap 판정 로직 검증용으로 노출
    @discardableResult
    func recordCallback(timestamp: Date = Date(), detail: String = "") -> TimeInterval? {
        let previous = lastCallbackAt.withLock { last -> Date? in
            defer { last = timestamp }
            return last
        }

        // log collect 추출 시 동적 문자열이 <private>로 마스킹되지 않도록 .public 명시
        logger.notice("콜백 수신 \(detail, privacy: .public)")

        guard let previous else { return nil }
        let gap = timestamp.timeIntervalSince(previous)
        guard gap >= gapThreshold else { return nil }
        logger.warning("수신 공백 \(gap, format: .fixed(precision: 2), privacy: .public)초 (기준 \(self.gapThreshold, privacy: .public)초)")
        return gap
    }
}

/// 앱 라이프사이클 전환을 센서 계측과 같은 서브시스템에 남겨,
/// 수신 공백이 백그라운드 진입·화면 잠금과 겹치는지 대조할 수 있게 한다.
final class AppLifecycleInstrumentation {
    private let observers: [NSObjectProtocol]

    init() {
        let logger = Logger(subsystem: SensorInstrumentation.subsystem, category: "lifecycle")
        // protectedData 알림은 화면 잠금/해제의 근사 신호 — 잠금 상태 yaw 드리프트 의심 구간 식별용
        let events: [(Notification.Name, String)] = [
            (UIApplication.didBecomeActiveNotification, "didBecomeActive"),
            (UIApplication.willResignActiveNotification, "willResignActive"),
            (UIApplication.didEnterBackgroundNotification, "didEnterBackground"),
            (UIApplication.willEnterForegroundNotification, "willEnterForeground"),
            (UIApplication.protectedDataWillBecomeUnavailableNotification, "protectedDataWillBecomeUnavailable(화면 잠금)"),
            (UIApplication.protectedDataDidBecomeAvailableNotification, "protectedDataDidBecomeAvailable(잠금 해제)"),
        ]
        observers = events.map { name, label in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { _ in
                logger.notice("\(label, privacy: .public)")
            }
        }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
#endif
