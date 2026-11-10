//
//  SettingsView.swift
//  FeatureSettings
//

import SwiftUI
import UIKit
import FeatureSettingsInterface
import CoreSensorsInterface

/// 설정 화면
internal struct SettingsView: View {
    @StateObject private var store: SettingsStore
    @Environment(\.openURL) private var openURL

    internal init(store: SettingsStore) {
        _store = StateObject(wrappedValue: store)
    }

    internal var body: some View {
        NavigationStack {
            Form {
                thresholdSection
                permissionSection
                aboutSection
            }
            .navigationTitle("설정")
        }
        .task {
            store.send(.load)
            store.send(.observeAuthorization)
        }
    }
}

// MARK: - 주행 감지 기준

private extension SettingsView {
    var thresholdSection: some View {
        Section {
            thresholdSlider(
                identifier: "accelerationThresholdSlider",
                title: "급가감속 기준",
                value: store.state.thresholds.accelerationKmhPerSec,
                range: 5...30,
                step: 0.1,
                format: { String(format: "%.1f km/h/s", $0) },
                onChange: { store.send(.changeAccelerationThreshold($0)) }
            )

            thresholdSlider(
                identifier: "leanAngleThresholdSlider",
                title: "뱅킹각 기준",
                value: store.state.thresholds.minLeanAngleDegrees,
                range: 10...55,
                step: 1,
                format: { String(format: "%.0f°", $0) },
                onChange: { store.send(.changeLeanAngleThreshold($0)) }
            )

            thresholdSlider(
                identifier: "stopSpeedThresholdSlider",
                title: "정차 판단 속도",
                value: store.state.thresholds.stopSpeedKmh,
                // 0이면 정차 감지가 꺼져 주차 중에도 시간·거리가 쌓이고 린앵글 이벤트가 잡힌다
                range: 1...10,
                step: 0.5,
                format: { String(format: "%.1f km/h", $0) },
                onChange: { store.send(.changeStopSpeedThreshold($0)) }
            )

            Button("기본값으로") {
                store.send(.resetToDefaults)
            }
            .disabled(!store.state.isCustomized)
            .accessibilityIdentifier("resetThresholdsButton")
        } header: {
            Text("주행 감지 기준")
        } footer: {
            Text("바꾼 기준은 다음 주행부터 적용됩니다. 정차 판단 속도 이하 구간은 주행 시간·거리에서 빠집니다.")
        }
    }

    func thresholdSlider(
        identifier: String,
        title: String,
        value: Double,
        range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String,
        onChange: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(format(value))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(get: { value }, set: onChange),
                in: range,
                step: step,
                // 조작이 끝나는 시점에만 저장해 드래그 중 쓰기를 피한다
                onEditingChanged: { editing in
                    if !editing { store.send(.commitChanges) }
                }
            )
            .accessibilityIdentifier(identifier)
            .accessibilityLabel(title)
            .accessibilityValue(format(value))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 위치 권한

private extension SettingsView {
    var permissionSection: some View {
        Section("위치 권한") {
            HStack {
                Text("현재 상태")
                Spacer()
                Text(authorizationDescription)
                    .foregroundStyle(authorizationTint)
            }

            if store.state.locationAuthorization != .always {
                Button("설정 앱에서 변경") {
                    openSettings()
                }
                .accessibilityIdentifier("openLocationSettingsButton")
            }
        }
    }

    var authorizationDescription: String {
        switch store.state.locationAuthorization {
        case .notDetermined: "확인 전"
        case .denied: "꺼짐"
        case .whenInUse: "앱 사용 중 허용"
        case .always: "항상 허용"
        }
    }

    var authorizationTint: Color {
        switch store.state.locationAuthorization {
        case .denied: .red
        case .notDetermined: .secondary
        case .whenInUse, .always: .primary
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

// MARK: - 앱 정보

private extension SettingsView {
    var aboutSection: some View {
        Section("앱 정보") {
            HStack {
                Text("버전")
                Spacer()
                Text(store.state.appVersion)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}
