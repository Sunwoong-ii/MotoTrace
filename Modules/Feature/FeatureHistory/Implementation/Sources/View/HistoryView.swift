import SwiftUI
import FeatureHistoryInterface

/// 라이딩 히스토리 화면
struct HistoryView: View {
    @StateObject private var store: HistoryStore
    
    init(store: HistoryStore) {
        self._store = StateObject(wrappedValue: store)
    }
    
    var body: some View {
        VStack {
            
        }
    }
}


