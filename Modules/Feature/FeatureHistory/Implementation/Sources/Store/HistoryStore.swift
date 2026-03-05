//
//  HistoryStore.swift
//  FeatureHistoryInterface
//
//  Created by 김선웅 on 3/5/26.
//

import Foundation
import FeatureHistoryInterface
import CoreDataStorageInterface

final class HistoryStore: ObservableObject {
    private let repository: TourRepositoryInterface
    
    @Published private(set) var state: HistoryState
    
    init(
        repository: TourRepositoryInterface,
        initialState: HistoryState = .init()
    ) {
        self.repository = repository
        self.state = initialState
    }
    
    func send(_ intent: HistoryIntent) {
        switch intent {
        case .fetchTours:
            fetchTours()
        }
    }
    
    private func fetchTours() {
        
    }
}
