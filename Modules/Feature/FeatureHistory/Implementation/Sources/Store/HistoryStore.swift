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
        case .deleteTour(let id):
            deleteTour(id: id)
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

    private func deleteTour(id: UUID) {
        Task {
            do {
                // 저장소 삭제가 성공한 뒤에만 목록에서 제거 — 실패했는데 화면에서만 사라지는 것을 막는다
                try await repository.deleteTour(id: id)
                state.tours.removeAll { $0.id == id }
            } catch {
                print("Failed to delete tour: \(error)")
            }
        }
    }
}
