import SwiftUI
import AppDI

/// 투어 Feature Assembler 프로토콜
public protocol TourFeatureAssembling {
    static func assemble(container: AppDIContainer, initialState: RidingState) -> AnyView
}
