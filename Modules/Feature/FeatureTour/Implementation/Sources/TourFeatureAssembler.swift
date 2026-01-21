import SwiftUI
import FeatureTourInterface

/// 투어 Feature Assembler
public enum TourFeatureAssembler: @preconcurrency TourFeatureAssembling {
    
    @MainActor
    public static func assemble(dependencies: TourDependencies) -> AnyView {
        let store = TourStore(dependencies: dependencies)
        return AnyView(TourView(store: store))
    }
}
