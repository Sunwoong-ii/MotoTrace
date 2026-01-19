import SwiftUI

/// 설정 Feature Builder 프로토콜
public protocol SettingsFeatureBuilding {
    static func build() -> AnyView
}
