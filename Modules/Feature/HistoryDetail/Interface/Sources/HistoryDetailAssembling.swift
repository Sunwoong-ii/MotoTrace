import SwiftUI
import AppDI

public protocol HistoryDetailAssembling {
    static func assemble(container: AppDIContainer, tourId: UUID) -> AnyView
}
