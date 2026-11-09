//
//  SettingsStore.swift
//  FeatureSettings
//

import Foundation
import FeatureSettingsInterface
import CoreTrackingInterface
import CoreSensorsInterface
import CoreDataStorageInterface

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var state: SettingsState

    private let thresholdsStore: TrackingThresholdsRepositoryInterface
    private let sensors: CoreSensorsInterface
    private var authorizationTask: Task<Void, Never>?

    init(
        thresholdsStore: TrackingThresholdsRepositoryInterface,
        sensors: CoreSensorsInterface,
        initialState: SettingsState = SettingsState()
    ) {
        self.thresholdsStore = thresholdsStore
        self.sensors = sensors
        self.state = initialState
    }

    deinit {
        authorizationTask?.cancel()
    }

    func send(_ intent: SettingsIntent) {
        switch intent {
        case .load:
            state.thresholds = thresholdsStore.load()
            state.appVersion = Self.readAppVersion()
        case .observeAuthorization:
            observeAuthorization()
        case .changeAccelerationThreshold(let value):
            // 급가속·급감속을 하나의 슬라이더로 다루므로 두 값을 같이 움직인다
            state.thresholds = state.thresholds.with(acceleration: value, deceleration: value)
        case .changeLeanAngleThreshold(let value):
            state.thresholds = state.thresholds.with(minLeanAngle: value)
        case .changeStopSpeedThreshold(let value):
            state.thresholds = state.thresholds.with(stopSpeed: value)
        case .commitChanges:
            thresholdsStore.save(state.thresholds)
        case .resetToDefaults:
            state.thresholds = TrackingPolicy.defaultThresholds
            thresholdsStore.save(state.thresholds)
        }
    }

    private func observeAuthorization() {
        guard authorizationTask == nil else { return }
        // 스트림이 끝나지 않으므로 루프 밖에서 self를 잡으면 store가 영영 해제되지 않는다
        let stream = sensors.authorizationStream()
        authorizationTask = Task { [weak self] in
            for await status in stream {
                guard let self else { return }
                self.state.locationAuthorization = status
            }
        }
    }

    private static func readAppVersion() -> String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(short) (\(build))"
    }
}

private extension TrackingThresholds {
    /// 값 타입이라 바꿀 항목만 지정해 새 인스턴스를 만든다
    func with(
        acceleration: Double? = nil,
        deceleration: Double? = nil,
        minLeanAngle: Double? = nil,
        stopSpeed: Double? = nil
    ) -> TrackingThresholds {
        TrackingThresholds(
            accelerationKmhPerSec: acceleration ?? accelerationKmhPerSec,
            decelerationKmhPerSec: deceleration ?? decelerationKmhPerSec,
            minLeanAngleDegrees: minLeanAngle ?? minLeanAngleDegrees,
            stopSpeedKmh: stopSpeed ?? stopSpeedKmh
        )
    }
}
