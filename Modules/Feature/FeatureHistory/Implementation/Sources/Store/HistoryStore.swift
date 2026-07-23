//
//  HistoryStore.swift
//  FeatureHistory
//
//  Created by 김선웅 on 3/5/26.
//

import Foundation
import FeatureHistoryInterface
import CoreDataStorageInterface

@MainActor
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
        Task {
            do {
                let dtos = try await repository.fetchAllTours()
                state.tours = dtos.map { dto in
                    HistoryRecord(
                        id: dto.id,
                        duration: dto.duration,
                        distance: dto.distance,
                        topSpeed: dto.topSpeed,
                        maxLeanAngle: dto.maxLeanAngle,
                        tourName: dto.tourName,
                        createdAt: dto.createdAt
                    )
                }
            } catch {
                print("Failed to fetch tours: \(error)")
            }
        }
    }
}
