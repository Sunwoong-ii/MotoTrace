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
                // 전체 목록을 변환해서 하나만 쓰는 낭비를 피하고 대상 투어만 조회
                guard let dto = try await repository.fetchTour(id: tourId) else {
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
                        .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) },
                    eventMarkers: Self.makeEventMarkers(from: dto.events)
                )
            } catch {
                print("🚨 [HistoryDetailStore] Failed to load tour error: \(error)")
            }
        }
    }

    /// 저장된 이벤트 DTO를 지도 마커로 변환 — 표시 문자열 조립까지 여기서 끝내
    /// View는 포맷 규칙을 모르게 한다. 필수 값이 빠졌거나 모르는 타입이면 마커를 만들지 않는다
    /// (순수 함수라 MainActor 격리가 불필요 — 테스트에서 격리 없이 호출)
    nonisolated static func makeEventMarkers(from events: [TourEventDTO]) -> [RideEventMarker] {
        events.compactMap { event in
            guard let type = RideEventMarker.EventType(rawValue: event.type) else { return nil }

            let displayValue: String
            switch type {
            case .rapidAcceleration, .rapidDeceleration:
                guard let endSpeed = event.endSpeed else {
                    displayValue = String(format: "%.0f", event.startSpeed)
                    break
                }
                var text = String(format: "%.0f→%.0f", event.startSpeed, endSpeed)
                if let start = event.startTime, let end = event.endTime {
                    text += String(format: " (%.1fs)", end.timeIntervalSince(start))
                }
                displayValue = text
            case .leanAngle:
                guard let leanAngle = event.leanAngle else { return nil }
                // 부호는 좌/우 구분이라 마커에서는 크기만 의미 있음
                displayValue = String(format: "%.0f° %.0fkm/h", abs(leanAngle), event.startSpeed)
            }

            return RideEventMarker(
                id: event.id,
                type: type,
                coordinate: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude),
                displayValue: displayValue
            )
        }
    }
}
