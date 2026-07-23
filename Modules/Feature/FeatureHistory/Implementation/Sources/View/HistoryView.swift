import SwiftUI
import AppDI
import FeatureHistoryInterface
import HistoryDetail

/// 라이딩 히스토리 화면
struct HistoryView: View {
    @StateObject private var store: HistoryStore
    let container: AppDIContainer

    init(store: HistoryStore, container: AppDIContainer) {
        self._store = StateObject(wrappedValue: store)
        self.container = container
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                if store.state.tours.isEmpty {
                    emptyView
                } else {
                    tourList
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            store.send(.fetchTours)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("History")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()

            Text("\(store.state.tours.count) rides")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tour List

    private var tourList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(groupedTours, id: \.day) { group in
                    Text(sectionTitle(group.day))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    ForEach(group.tours, id: \.id) { tour in
                        NavigationLink {
                            HistoryDetailFeatureBuilder.assemble(
                                container: container,
                                tourId: tour.id
                            )
                        } label: {
                            tourCell(tour)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Tour Cell

    private func tourCell(_ tour: HistoryRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(tour.tourName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(formatDate(tour.createdAt))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                // 4개가 한 줄에 안 맞는 좁은 화면에서는 최고속도 배지를 자동으로 뺀다
                ViewThatFits(in: .horizontal) {
                    badgeRow(tour, includeTopSpeed: true)
                    badgeRow(tour, includeTopSpeed: false)
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Stat Badges

    private func badgeRow(_ tour: HistoryRecord, includeTopSpeed: Bool) -> some View {
        HStack(spacing: 5) {
            statBadge(icon: "location.fill", text: String(format: "%.1fkm", tour.distance), tint: .blue)
            statBadge(icon: "clock", text: formatDuration(tour.duration), tint: .primary)
            if includeTopSpeed {
                statBadge(icon: "speedometer", text: String(format: "%.0fkm/h", tour.topSpeed), tint: .green)
            }
            statBadge(icon: nil, text: String(format: "%.0f° max", tour.maxLeanAngle), tint: .orange)
        }
    }

    private func statBadge(icon: String?, text: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: Capsule())
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

    // MARK: - Date Grouping

    /// createdAt 기준 날짜별 그룹. store.state.tours가 이미 내림차순이라 순서를 보존해 묶는다.
    private var groupedTours: [(day: Date, tours: [HistoryRecord])] {
        let calendar = Calendar.current
        var order: [Date] = []
        var buckets: [Date: [HistoryRecord]] = [:]
        for tour in store.state.tours {
            let day = calendar.startOfDay(for: tour.createdAt)
            if buckets[day] == nil {
                buckets[day] = []
                order.append(day)
            }
            buckets[day]?.append(tour)
        }
        return order.map { (day: $0, tours: buckets[$0] ?? []) }
    }

    private func sectionTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "오늘" }
        if calendar.isDateInYesterday(day) { return "어제" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        // 올해면 연도 생략, 지난 해면 연도까지 표기
        let sameYear = calendar.component(.year, from: day) == calendar.component(.year, from: Date())
        formatter.dateFormat = sameYear ? "M월 d일" : "yyyy년 M월 d일"
        return formatter.string(from: day)
    }

    // MARK: - Formatters

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 · a h:mm"
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
