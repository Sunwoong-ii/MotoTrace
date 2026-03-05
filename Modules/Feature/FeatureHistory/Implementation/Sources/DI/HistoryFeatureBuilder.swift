import SwiftUI
import FeatureHistoryInterface
import AppDI

/// 히스토리 Feature Builder
public enum HistoryFeatureBuilder: HistoryAssembling {
    public static func assemble(container: AppDI.AppDIContainer) -> AnyView {
        AnyView(HistoryView())
    }
}
