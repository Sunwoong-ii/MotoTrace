import Foundation

/// 설정 Feature의 State (MVI 패턴)
public struct SettingsState {
    public var isDarkMode: Bool
    
    public init(isDarkMode: Bool = false) {
        self.isDarkMode = isDarkMode
    }
}
