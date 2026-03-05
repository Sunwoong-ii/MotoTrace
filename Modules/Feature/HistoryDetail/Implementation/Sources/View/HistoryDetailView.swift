import SwiftUI
import HistoryDetailInterface

struct HistoryDetailView: View {
    @StateObject private var store: HistoryDetailStore
    
    init(store: HistoryDetailStore) {
        _store = StateObject(wrappedValue: store)
    }
    
    var body: some View {
        Text("HistoryDetail")
    }
}
