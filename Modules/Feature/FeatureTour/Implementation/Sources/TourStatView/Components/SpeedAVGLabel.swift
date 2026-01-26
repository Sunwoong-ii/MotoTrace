//
//  SpeedAVGLabel.swift
//  FeatureTour
//
//  Created by 웅 on 1/26/26.
//

import SwiftUI

struct SpeedAVGLabel: View {
    let value: String
    
    var body: some View {
        VStack {
            Text("평균 속도")
            
            HStack {
                Text(value)
                    .font(.title)
                    .fontWeight(.heavy)
                
                Text("km/h")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        }
    }
}
