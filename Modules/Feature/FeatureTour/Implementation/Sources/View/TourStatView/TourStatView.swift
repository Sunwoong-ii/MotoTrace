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
    let trackingStatus: TrackingStatus
    let onPause: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
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
            
            // PAUSE + STOP 버튼
            HStack(spacing: 10) {
                TrackingButton(status: trackingStatus, action: onPause)
                
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: TourDesign.buttonCornerRadius))
                        .shadow(color: Color.red.opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
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
                trackingStatus: .tracking,
                onPause: {},
                onStop: {}
            )
        }
    }
}
