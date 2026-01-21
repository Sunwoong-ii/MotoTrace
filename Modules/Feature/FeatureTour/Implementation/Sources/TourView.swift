//  RidingStore.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/21.
//

import SwiftUI
import FeatureTourInterface

/// 라이딩 트래킹 화면
internal struct TourView: View {
    @StateObject private var store: RidingStore
    
    internal init(store: RidingStore = RidingStore()) {
        _store = StateObject(wrappedValue: store)
    }
    
    internal var body: some View {
        Text("Riding")
            .onAppear { store.send(.startTracking) }
            .onDisappear { store.send(.stopTracking) }
    }
}
