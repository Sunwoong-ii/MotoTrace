import SwiftUI
import FeatureHistoryInterface

/// 라이딩 히스토리 화면
struct HistoryView: View {
    @StateObject private var store: HistoryStore
    
    init(store: HistoryStore) {
        self._store = StateObject(wrappedValue: store)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if store.state.tours.isEmpty {
                    emptyView
                } else {
                    tourList
                }
            }
            .navigationTitle("History")
        }
        .onAppear {
            store.send(.fetchTours)
        }
    }
    
    // MARK: - Tour List
    
    private var tourList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.state.tours, id: \.id) { tour in
                    tourCell(tour)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Tour Cell
    
    private func tourCell(_ tour: HistoryRecord) -> some View {
        HStack(spacing: 14) {
            // 아이콘
            Image(systemName: "motorcycle")
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 제목 + 날짜
            VStack(alignment: .leading, spacing: 4) {
                Text(tour.tourName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(formatDate(tour.createdAt))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "road.lanes")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("아직 기록된 투어가 없습니다")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            Text("투어 탭에서 라이딩을 시작해보세요")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Formatters
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd  HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm %02ds", minutes, secs)
        }
    }
}
