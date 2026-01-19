import SwiftUI
import FeatureSettingsInterface

/// 설정 Feature Builder
public enum SettingsFeatureBuilder: SettingsFeatureBuilding {
    public static func build() -> AnyView {
        AnyView(SettingsView())
    }
}
