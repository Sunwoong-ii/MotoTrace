//
//  LeanAngleView.swift
//  FeatureTour
//
//  지도 위 좌측 린앵글 오버레이
//

import SwiftUI

struct LeanAngleView: View {
    let angle: String
    
    private var angleValue: Double {
        Double(angle) ?? 0
    }
    
    private var direction: String {
        if angleValue > 0.5 { return "right" }
        else if angleValue < -0.5 { return "left" }
        return ""
    }
    private var displayAngle: String {
        let absValue = abs(angleValue)
        if absValue < 1 {
            return String(format: "%.0f", absValue)
        }
        return String(format: "%.0f", absValue) // 소수점 없애고 정수로만 표시
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 12)
                    
                    ZStack {
                        // 틸트 표시 바
                        RoundedRectangle(cornerRadius: 2)
                            .fill(TourDesign.gaugeTrack)
                            .frame(width: 50, height: 4)
                        
                        // 현재 틸트 표시
                        RoundedRectangle(cornerRadius: 2)
                            .fill(TourDesign.accentOrange)
                            .frame(width: 50, height: 4)
                            .rotationEffect(.degrees(-angleValue))
                            .animation(.easeOut(duration: 0.2), value: angleValue)
                    }
                    
                    Spacer()
                }
                
                // 앵글 텍스트
                VStack(spacing: 0) {
                    Spacer().frame(height: 14)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(displayAngle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(TourDesign.textPrimary)
                        
                        Text("°")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(TourDesign.textPrimary)
                    }
                }
            }
            .frame(width: 60, height: 60)
            
            Text("LEAN ANGLE")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(TourDesign.labelGray)
            
            // 방향 뱃지
            if !direction.isEmpty {
                Text(direction)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(TourDesign.accentOrange)
                    )
            }
        }
        .padding(10)
        .background(TourDesign.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TourDesign.cardCornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

#Preview {
    LeanAngleView(angle: "-12.3")
        .padding()
        .background(Color.gray.opacity(0.2))
}
