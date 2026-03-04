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
    var action: () -> Void = {}
    
    private var config: ButtonConfig {
        switch status {
        case .idle, .paused:
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
        case .tracking:
            return ButtonConfig(
                icon: "pause.fill",
                title: "PAUSE RECORDING",
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
                    .foregroundStyle(.white)
                
                Text(config.title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(1.2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(config.gradient)
            .clipShape(RoundedRectangle(cornerRadius: TourDesign.buttonCornerRadius))
            .shadow(
                color: TourDesign.primaryBlue.opacity(0.35),
                radius: 12, y: 6
            )
        }
        .buttonStyle(.plain)
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
