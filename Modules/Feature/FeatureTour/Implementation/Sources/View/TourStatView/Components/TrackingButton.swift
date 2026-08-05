//
//  TrackingButton.swift
//  FeatureTour
//
//  시작 / 일시정지 버튼
//

import SwiftUI
import FeatureTourInterface

struct TrackingButton: View {
    let status: TrackingStatus
    var isEnabled: Bool = true
    var action: () -> Void = {}

    /// 비활성 상태에서는 색과 그림자를 죽여 누를 수 없다는 것을 시각적으로 알린다
    private var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [TourDesign.gaugeTrack, TourDesign.gaugeTrack.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var config: ButtonConfig {
        switch status {
        case .idle:
            return ButtonConfig(
                icon: "play.fill",
                title: "START RECORDING",
                gradient: LinearGradient(
                    colors: [
                        TourDesign.primaryBlue,
                        TourDesign.primaryBlue.opacity(0.85)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .paused:
            return ButtonConfig(
                icon: "play.fill",
                title: "RESTART",
                gradient: LinearGradient(
                    colors: [
                        TourDesign.gpsGreen,
                        TourDesign.gpsGreen.opacity(0.85)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .tracking:
            return ButtonConfig(
                icon: "pause.fill",
                title: "PAUSE",
                gradient: LinearGradient(
                    colors: [
                        TourDesign.primaryBlue,
                        TourDesign.primaryBlue.opacity(0.85)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: config.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isEnabled ? .white : TourDesign.textSecondary)

                Text(config.title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(isEnabled ? .white : TourDesign.textSecondary)
                    .tracking(1.2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? config.gradient : disabledGradient)
            .clipShape(RoundedRectangle(cornerRadius: TourDesign.buttonCornerRadius))
            .shadow(
                color: isEnabled ? TourDesign.primaryBlue.opacity(0.35) : .clear,
                radius: 12, y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct ButtonConfig {
    let icon: String
    let title: String
    let gradient: LinearGradient
}

#Preview("Start") {
    TrackingButton(status: .idle)
        .padding(24)
}

#Preview("Pause") {
    TrackingButton(status: .tracking)
        .padding(24)
}
