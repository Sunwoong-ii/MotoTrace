import Foundation

/// 히스토리 Feature의 State (MVI 패턴)
public struct HistoryState {
    public var rides: [String]
    
    public init(rides: [String] = []) {
        self.rides = rides
    }
}
