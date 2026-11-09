import SwiftUI
import AppDI

/// 설정 Feature Assembler 프로토콜
public protocol SettingsAssembling {
    static func assemble(container: AppDIContainer) -> AnyView
}
