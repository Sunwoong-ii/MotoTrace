import SwiftUI
import FeatureHistoryInterface
import AppDI
import CoreDataStorageInterface

/// 히스토리 Feature Builder
public enum HistoryAssembler: @preconcurrency HistoryAssembling {
    
    @MainActor
    public static func assemble(container: AppDIContainer) -> AnyView {
        let repository = container.resolve(TourRepositoryInterface.self)
        let store = HistoryStore(repository: repository)
        return AnyView(HistoryView(store: store, container: container))
    }
}
