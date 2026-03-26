//
//  StatCard.swift
//  FeatureTour
//
//  TOP Speed / MAX Lean Angle 카드
//

import SwiftUI

struct StatCard: View {
    enum StatCardType {
        case topSpeed
        case leanAngle

        var title: String {
            switch self {
            case .topSpeed: "Top Speed"
            case .leanAngle: "Max Angle"
            }
        }
        
        var suffix: String {
            switch self {
            case .topSpeed: ""
            case .leanAngle: "°"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .topSpeed: TourDesign.primaryBlue
            case .leanAngle: TourDesign.accentOrange
            }
        }
    }
    
    let type: StatCardType
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(type.title)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(type.accentColor)
                .tracking(0.8)
            
            Text(value + type.suffix)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(TourDesign.textPrimary)
        }
        .frame(width: 70, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.accentColor.opacity(0.25), lineWidth: 1)
                .fill(type.accentColor.opacity(0.04))
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCard(type: .topSpeed, value: "142")
        StatCard(type: .leanAngle, value: "49")
    }
    .padding()
}
