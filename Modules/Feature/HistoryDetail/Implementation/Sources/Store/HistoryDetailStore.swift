import Foundation
import CoreLocation
import HistoryDetailInterface
import CoreDataStorageInterface

@MainActor
final class HistoryDetailStore: ObservableObject {
    @Published private(set) var state: HistoryDetailState
    
    private let repository: TourRepositoryInterface
    private let tourId: UUID
    
    init(
        repository: TourRepositoryInterface,
        tourId: UUID,
        initialState: HistoryDetailState = .init()
    ) {
        self.repository = repository
        self.tourId = tourId
        self.state = initialState
    }
    
    func send(_ intent: HistoryDetailIntent) {
        switch intent {
        case .loadTour:
            loadTour()
        }
    }
    
    private func loadTour() {
        Task {
            do {
                let tours = try await repository.fetchAllTours()
                guard let dto = tours.first(where: { $0.id == tourId }) else { return }
                
                state.tourName = dto.tourName
                state.createdAt = dto.createdAt
                state.duration = dto.duration
                state.distance = dto.distance
                state.avgSpeed = dto.avgSpeed
                state.topSpeed = dto.topSpeed
                state.maxLeanAngle = dto.maxLeanAngle
                state.routeCoordinates = dto.locations
                    .sorted { $0.timestamp < $1.timestamp }
                    .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            } catch {
                print("Failed to load tour: \(error)")
            }
        }
    }
}
