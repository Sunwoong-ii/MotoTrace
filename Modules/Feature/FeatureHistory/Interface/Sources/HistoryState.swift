import Foundation

/// 히스토리 Feature의 State (MVI 패턴)
public struct HistoryState {
    public var tours: [HistoryRecord]
    
    public init(tours: [HistoryRecord] = []) {
        self.tours = tours
    }
}

