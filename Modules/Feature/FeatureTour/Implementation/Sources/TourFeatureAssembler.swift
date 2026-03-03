import SwiftUI
import AppDI
import CoreSensorsInterface
import CoreTrackingInterface
import FeatureTourInterface
import CoreDataStorageInterface

/// 투어 Feature Assembler
public enum TourFeatureAssembler: @preconcurrency TourFeatureAssembling {
    
    @MainActor
    public static func assemble(container: AppDIContainer, initialState: TourState) -> AnyView {
        let sensors = container.resolve(CoreSensorsInterface.self)
        let repository = container.resolve(TourRepositoryInterface.self)
        let analyzer = container.resolve(
            TrackingAnalyzerInterface.self,
            with: CoreTrackingDependencies()
        )
        let store = TourStore(
            sensors: sensors,
            analyzer: analyzer,
            repository: repository,
            initialState: initialState
        )
        return AnyView(TourView(store: store))
    }
}
