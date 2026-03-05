import SwiftUI
import HistoryDetailInterface
import AppDI
import CoreDataStorageInterface

public enum HistoryDetailFeatureBuilder: @preconcurrency HistoryDetailAssembling {
    
    @MainActor
    public static func assemble(container: AppDIContainer, tourId: UUID) -> AnyView {
        let repository = container.resolve(TourRepositoryInterface.self)
        let store = HistoryDetailStore(repository: repository, tourId: tourId)
        return AnyView(HistoryDetailView(store: store))
    }
}
