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
        // 화면 잠금 방지 등 주행 세션 라이프사이클에 묶인 기기 런타임 — 피처 로컬이라 직접 생성
        let rideSessionRuntime = SystemRideSessionRuntime()
        let store = TourStore(
            sensors: sensors,
            analyzer: analyzer,
            repository: repository,
            sessionStore: sessionStore,
            rideSessionRuntime: rideSessionRuntime,
            initialState: initialState
        )
        return AnyView(TourView(store: store))
    }
}
