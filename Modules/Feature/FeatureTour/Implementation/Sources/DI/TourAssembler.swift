import SwiftUI
import AppDI
import CoreSensorsInterface
import CoreTrackingInterface
import CoreDataStorageInterface
import FeatureTourInterface

/// 투어 Feature Assembler
public enum TourAssembler: @preconcurrency TourFeatureAssembling {
    
    @MainActor
    public static func assemble(container: AppDIContainer, initialState: TourState) -> AnyView {
        let sensors = container.resolve(CoreSensorsInterface.self)
        let analyzer = container.resolve(
            TrackingAnalyzerInterface.self,
            with: CoreTrackingDependencies()
        )
        let repository = container.resolve(TourRepositoryInterface.self)
        let sessionStore = container.resolve(TrackingSessionRepositoryInterface.self)
        let store = TourStore(
            sensors: sensors,
            analyzer: analyzer,
            repository: repository,
            sessionStore: sessionStore,
            initialState: initialState
        )
        return AnyView(TourView(store: store))
    }
}
