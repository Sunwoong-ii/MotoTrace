import SwiftUI
import CoreSensorsInterface
import CoreTrackingInterface

/// 투어 Feature 의존성 묶음
public struct TourDependencies {
    public let sensors: CoreSensorsInterface
    public let analyzer: TrackingAnalyzerInterface
    public let initialState: RidingState
    
    public init(
        sensors: CoreSensorsInterface,
        analyzer: TrackingAnalyzerInterface,
        initialState: RidingState = RidingState()
    ) {
        self.sensors = sensors
        self.analyzer = analyzer
        self.initialState = initialState
    }
}

/// 투어 Feature Assembler 프로토콜
public protocol TourFeatureAssembling {
    static func assemble(dependencies: TourDependencies) -> AnyView
}
