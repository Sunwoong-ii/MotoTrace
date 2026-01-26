//
//  StatCard.swift
//  FeatureTour
//
//  Created by 웅 on 1/26/26.
//

import SwiftUI

struct StatCard: View {
    enum StatCardType {
        case leanAngle
        case topSpeed
        
        var image: String {
            switch self {
            case .leanAngle: "angle"
            case .topSpeed: "motorcycle"
            }
        }
        
        var title: String {
            switch self {
            case .leanAngle: "Lean Angle"
            case .topSpeed: "Top Speed"
            }
        }
        
        var suffix: String {
            switch self {
            case .leanAngle: "°"
            case .topSpeed: ""
            }
        }
    }
    
    let type: StatCardType
    let value: String
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            
            Image(systemName: type.image)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            
            Text(type.title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(value + type.suffix)
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
        }
        .frame(width: 70, height: 80)
    }
}
