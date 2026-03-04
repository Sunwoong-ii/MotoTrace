//
//  TourStatView.swift
//  FeatureTour
//
//  하단 통계 패널 (트래킹 중 표시)
//

import SwiftUI
import FeatureTourInterface

struct TourStatView: View {
    let duration: String
    let distance: String
    let avgSpeed: String
    let topSpeed: String
    let topLeanAngle: String
    let onPause: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 드래그 핸들
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
            
            // DURATION / DISTANCE
            HStack(spacing: 32) {
                StatLabel(type: .duration, value: duration)
                StatLabel(type: .distance, value: distance)
                Spacer()
            }
            
            // AVG SPEED + TOP / MAX 카드
            HStack(alignment: .bottom) {
                SpeedAVGLabel(value: avgSpeed)
                
                Spacer()
                
                HStack(spacing: 8) {
                    StatCard(type: .topSpeed, value: topSpeed)
                    StatCard(type: .leanAngle, value: topLeanAngle)
                }
            }
            
            // PAUSE 버튼
            TrackingButton(status: .tracking, action: onPause)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            TourDesign.cardBackground
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 20, y: -4)
        )
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            TourStatView(
                duration: "1h 24m",
                distance: "42.5",
                avgSpeed: "85",
                topSpeed: "142",
                topLeanAngle: "49",
                onPause: {}
            )
        }
    }
}
