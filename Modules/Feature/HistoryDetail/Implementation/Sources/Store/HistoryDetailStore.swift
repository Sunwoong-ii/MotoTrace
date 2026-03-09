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
                guard let dto = tours.first(where: { $0.id == tourId }) else {
                    print("⚠️ [HistoryDetailStore] loadTour 실패: tourId(\(tourId))에 해당하는 데이터를 찾을 수 없습니다.")
                    return
                }
                
                print("✅ [HistoryDetailStore] loadTour 성공: \(dto.tourName), location count: \(dto.locations.count)")
                
                state = HistoryDetailState(
                    tourName: dto.tourName,
                    createdAt: dto.createdAt,
                    duration: dto.duration,
                    distance: dto.distance,
                    avgSpeed: dto.avgSpeed,
                    topSpeed: dto.topSpeed,
                    maxLeanAngle: dto.maxLeanAngle,
                    routeCoordinates: dto.locations
                        .sorted { $0.timestamp < $1.timestamp }
                        .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                )
            } catch {
                print("🚨 [HistoryDetailStore] Failed to load tour error: \(error)")
            }
        }
    }
}
