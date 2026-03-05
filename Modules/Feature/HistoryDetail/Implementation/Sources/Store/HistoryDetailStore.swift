import Foundation
import HistoryDetailInterface

@MainActor
final class HistoryDetailStore: ObservableObject {
    @Published private(set) var state: HistoryDetailState
    
    init(initialState: HistoryDetailState = .init()) {
        self.state = initialState
    }
    
    func send(_ intent: HistoryDetailIntent) {
        switch intent {
        
        }
    }
}
