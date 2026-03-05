import SwiftUI
import AppDI

public protocol HistoryDetailAssembling {
    static func assemble(container: AppDIContainer) -> AnyView
}
