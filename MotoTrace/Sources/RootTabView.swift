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
import FeatureHistory
import FeatureHistoryInterface

struct RootTabView: View {
    let container: AppDIContainer
    
    var body: some View {
        TabView {
            Tab("Tour", systemImage: "map") {
                TourAssembler.assemble(
                    container: container,
                    initialState: TourState()
                )
            }
            
            Tab("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                HistoryAssembler.assemble(container: container)
            }
        }
        .tint(.blue)
    }
}
