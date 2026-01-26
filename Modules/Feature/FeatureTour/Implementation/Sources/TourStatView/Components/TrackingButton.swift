//
//  TrackingButton.swift
//  FeatureTour
//
//  Created by 웅 on 1/26/26.
//

import SwiftUI
import FeatureTourInterface

struct TrackingButton: View {
    private enum TrackingButtonType {
        case pause
        case stop
        case start
        
        var image: String {
            switch self {
            case .pause: return "pause.circle"
            case .stop: return "stop.circle"
            case .start: return "play.fill"
            }
        }
        
        var title: String {
            switch self {
            case .pause: return "중지"
            case .stop: return "종료"
            case .start: return "시작"
            }
        }
    }
    
    let status: TrackingStatus
    
    private var buttons: [TrackingButtonType] {
        switch status {
        case .idle, .paused: return [.start]
        case .tracking: return [.pause, .stop]
        }
    }
    
    var body: some View {
        HStack {
            ForEach(buttons, id: \.self) { (button: TrackingButtonType) in
                trackingButton(button)
            }
        }
        .frame(height: 45)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func trackingButton(_ type: TrackingButtonType) -> some View {
        HStack(spacing: 20) {
            Image(systemName: type.image)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            
            Text(type.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
}
