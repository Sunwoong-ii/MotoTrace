//
//  RootTabView.swift
//  MotoTrace
//
//  Created by 웅 on 1/23/26.
//

import SwiftUI
import AppDI
import FeatureTour
import FeatureTourInterface

struct RootTabView: View {
    let container: AppDIContainer
    
    var body: some View {
        TabView {
            Tab("Tour", systemImage: "figure.outdoor.cycle") {
                TourFeatureAssembler.assemble(
                    container: container,
                    initialState: TourState()
                )
            }
            
            Tab("History", systemImage: "clock.arrow.counterclockwise") {
                Text("History")
            }
            
            Tab("Settings", systemImage: "gearshape.fill") {
                Text("Settings")
            }
        }
        .tint(.blue)
    }
}
