import SwiftUI
import AppDI

public protocol HistoryAssembling {
    static func assemble(container: AppDIContainer) -> AnyView
}
