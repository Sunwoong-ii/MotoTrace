//
//  StatLabel.swift
//  FeatureTour
//
//  Created by 웅 on 1/26/26.
//

import SwiftUI

struct StatLabel: View {
    enum StatType {
        case duration
        case distance
        
        var title: String {
            switch self {
            case .duration: "Duration"
            case .distance: "Distance"
            }
        }
    }
    
    let type: StatType
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(type.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
    }
}
