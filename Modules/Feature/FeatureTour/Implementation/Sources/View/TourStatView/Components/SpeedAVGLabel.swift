//
//  SpeedAVGLabel.swift
//  FeatureTour
//
//  하단 패널 평균 속도 표시
//

import SwiftUI

struct SpeedAVGLabel: View {
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AVG SPEED")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TourDesign.labelGray)
                .tracking(0.8)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(TourDesign.textPrimary)
                
                Text("km/h")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TourDesign.labelGray)
            }
        }
    }
}

#Preview {
    SpeedAVGLabel(value: "85")
        .padding()
}
