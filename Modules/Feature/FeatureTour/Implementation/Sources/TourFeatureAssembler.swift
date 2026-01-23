import SwiftUI
import AppDI
import CoreSensorsInterface
import CoreTrackingInterface
import FeatureTourInterface

/// 투어 Feature Assembler
public enum TourFeatureAssembler: @preconcurrency TourFeatureAssembling {
    
    @MainActor
    public static func assemble(container: AppDIContainer, initialState: RidingState) -> AnyView {
        let sensors = container.resolve(CoreSensorsInterface.self)
        let analyzer = container.resolve(
            TrackingAnalyzerInterface.self,
            with: CoreTrackingDependencies()
        )
        let store = TourStore(
            sensors: sensors,
            analyzer: analyzer,
            initialState: initialState
        )
        return AnyView(TourView(store: store))
    }
}
