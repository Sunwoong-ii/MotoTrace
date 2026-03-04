//
//  StatLabel.swift
//  FeatureTour
//
//  DURATION / DISTANCE 레이블
//

import SwiftUI

struct StatLabel: View {
    enum StatType {
        case duration
        case distance
        
        var title: String {
            switch self {
            case .duration: "DURATION"
            case .distance: "DISTANCE"
            }
        }
        
        var suffix: String {
            switch self {
            case .duration: ""
            case .distance: " km"
            }
        }
    }
    
    let type: StatType
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(type.title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(TourDesign.labelGray)
                .tracking(0.8)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(TourDesign.textPrimary)
                
                if !type.suffix.isEmpty {
                    Text(type.suffix)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TourDesign.labelGray)
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: 30) {
        StatLabel(type: .duration, value: "1h 24m")
        StatLabel(type: .distance, value: "42.5")
    }
    .padding()
}
