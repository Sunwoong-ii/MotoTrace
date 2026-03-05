import SwiftUI
import FeatureHistoryInterface
import AppDI
import CoreDataStorageInterface

public enum HistoryFeatureAssembler: @preconcurrency HistoryAssembling {
    @MainActor
    public static func assemble(container: AppDIContainer) -> AnyView {
        let repository = container.resolve(TourRepositoryInterface.self)
        let store = HistoryStore(repository: repository)
        return AnyView(HistoryView(store: store))
    }
}
