//
//  RootTabView.swift
//  MotoTrace
//
//  Created by 웅 on 1/23/26.
//

import SwiftUI
import AppDI
import CoreSensorsInterface
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
        .task {
            // 위치가 핵심 기능이므로 앱 시작 시 미리 When-In-Use 권한 요청
            // (이미 결정된 상태면 시스템이 무시. Always 승격은 트래킹 시작 시 TourStore가 요청)
            container.resolve(CoreSensorsInterface.self).requestWhenInUseAuthorization()
        }
    }
}
