//
//  SpeedGaugeView.swift
//  FeatureTour
//
//  지도 위 좌측 속도 게이지 오버레이
//

import SwiftUI

struct SpeedGaugeView: View {
    let speed: String
    let maxSpeed: Double
    
    private var speedValue: Double {
        Double(speed) ?? 0
    }
    
    private var progress: Double {
        min(speedValue / maxSpeed, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // 배경 트랙
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        TourDesign.gaugeTrack,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                
                // 진행 링
                Circle()
                    .trim(from: 0, to: progress * 0.75)
                    .stroke(
                        TourDesign.primaryBlue,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .animation(.easeOut(duration: 0.3), value: progress)
                
                // 속도 텍스트
                VStack(spacing: 0) {
                    Text(speed)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(TourDesign.textPrimary)
                    
                    Text("KM/H")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(TourDesign.labelGray)
                }
            }
            .frame(width: 60, height: 60)
            
            Text("SPEED")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(TourDesign.labelGray)
        }
        .padding(10)
        .background(TourDesign.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TourDesign.cardCornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

#Preview {
    SpeedGaugeView(speed: "85", maxSpeed: 200)
        .padding()
        .background(Color.gray.opacity(0.2))
}
