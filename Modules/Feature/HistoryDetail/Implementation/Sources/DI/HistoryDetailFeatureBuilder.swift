import SwiftUI
import HistoryDetailInterface
import AppDI

public enum HistoryDetailFeatureBuilder: HistoryDetailAssembling {
    public static func assemble(container: AppDIContainer) -> AnyView {
        let store = HistoryDetailStore()
        return AnyView(HistoryDetailView(store: store))
    }
}
