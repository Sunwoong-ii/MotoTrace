//
//  TourStatView.swift
//  FeatureTour
//
//  Created by 웅 on 1/26/26.
//

import SwiftUI
import FeatureTourInterface

struct TourStatView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                StatLabel(type: .duration, value: "1h 24m")
                StatLabel(type: .distance, value: "4.25 km")
                Spacer()
            }
            
            HStack {
                SpeedAVGLabel(value: "85")
                
                Color.clear
                    .frame(maxWidth: 40)
                
                StatCard(type: .topSpeed, value: "142")
                StatCard(type: .leanAngle, value: "49")
            }
            
            TrackingButton(status: .idle)
        }
        .padding(20)
        .background(Color.white)
        .shadow(radius: 5)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TourStatView()
        .frame(width: 350, height: 250)
}
