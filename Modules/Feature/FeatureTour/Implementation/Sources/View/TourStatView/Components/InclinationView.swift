//
//  InclinationView.swift
//  FeatureTour
//
//  지도 위 좌측 경사각 오버레이
//

import SwiftUI

struct InclinationView: View {
    let inclination: String

    private var value: Double {
        Double(inclination) ?? 0
    }

    private var absValue: Double { abs(value) }

    private var direction: String {
        if value > 0.5 { return "▲" }
        if value < -0.5 { return "▼" }
        return "—"
    }

    private var directionColor: Color {
        if value > 0.5 { return Color(red: 0.2, green: 0.8, blue: 0.4) }   // 오르막: 초록
        if value < -0.5 { return Color(red: 1.0, green: 0.45, blue: 0.3) } // 내리막: 주황
        return TourDesign.labelGray
    }

    var body: some View {
        VStack(spacing: 4) {
            // 경사 시각화 바
            ZStack {
                // 배경 바
                RoundedRectangle(cornerRadius: 2)
                    .fill(TourDesign.gaugeTrack)
                    .frame(width: 4, height: 44)

                // 경사 채움 (위 또는 아래)
                VStack(spacing: 0) {
                    if value >= 0 {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(directionColor)
                            .frame(width: 4, height: min(CGFloat(absValue / 30.0) * 44, 44))
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(directionColor)
                            .frame(width: 4, height: min(CGFloat(absValue / 30.0) * 44, 44))
                        Spacer()
                    }
                }
                .frame(height: 44)
                .animation(.easeOut(duration: 0.2), value: value)

                // 수평 중심선
                Rectangle()
                    .fill(TourDesign.textSecondary.opacity(0.4))
                    .frame(width: 12, height: 1)
            }
            .frame(width: 20, height: 40)

            // 각도 텍스트
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(String(format: "%.0f", absValue))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(TourDesign.textPrimary)
                Text("°")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(TourDesign.textPrimary)
            }

            // 방향 아이콘
            Text(direction)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(directionColor)

            Text("Incline")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(TourDesign.labelGray)
        }
        .padding(8)
        .background(TourDesign.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TourDesign.cardCornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

#Preview {
    HStack(spacing: 12) {
        InclinationView(inclination: "12.5")
        InclinationView(inclination: "-8.0")
        InclinationView(inclination: "0")
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
