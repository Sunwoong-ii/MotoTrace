import SwiftUI

/// 히스토리 Feature Builder 프로토콜
public protocol HistoryFeatureBuilding {
    static func build() -> AnyView
}
