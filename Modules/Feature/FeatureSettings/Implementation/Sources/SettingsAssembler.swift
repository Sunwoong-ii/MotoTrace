import SwiftUI
import AppDI
import FeatureSettingsInterface
import CoreSensorsInterface
import CoreDataStorageInterface

/// 설정 Feature Assembler
public enum SettingsAssembler: @preconcurrency SettingsAssembling {

    @MainActor
    public static func assemble(container: AppDIContainer) -> AnyView {
        let thresholdsStore = container.resolve(TrackingThresholdsRepositoryInterface.self)
        let sensors = container.resolve(CoreSensorsInterface.self)
        let store = SettingsStore(thresholdsStore: thresholdsStore, sensors: sensors)
        return AnyView(SettingsView(store: store))
    }
}
