import SwiftUI
import FeatureHistoryInterface

/// 히스토리 Feature Builder
public enum HistoryFeatureBuilder: HistoryFeatureBuilding {
    public static func build() -> AnyView {
        AnyView(HistoryView())
    }
}
