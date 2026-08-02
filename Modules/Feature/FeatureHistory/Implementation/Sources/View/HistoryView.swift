import SwiftUI
import AppDI
import FeatureHistoryInterface
import HistoryDetail

/// 라이딩 히스토리 화면
struct HistoryView: View {
    @StateObject private var store: HistoryStore
    let container: AppDIContainer

    /// 삭제 확인을 기다리는 대상 — 확인 alert에 투어명을 보여주기 위해 레코드째 보관한다
    @State private var pendingDeletion: HistoryRecord?

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
        .alert(
            "기록을 삭제할까요?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { tour in
            Button("삭제", role: .destructive) {
                store.send(.deleteTour(id: tour.id))
                pendingDeletion = nil
            }
            Button("취소", role: .cancel) {
                pendingDeletion = nil
            }
        } message: { tour in
            Text("'\(tour.tourName)'의 주행 경로와 기록이 모두 삭제되며 되돌릴 수 없습니다.")
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
        // 스와이프 삭제(.swipeActions)가 List 전용이라 List를 쓰고, 기본 크롬은 걷어내 카드 디자인을 유지한다
        List {
            ForEach(groupedTours, id: \.day) { group in
                Section {
                    ForEach(group.tours, id: \.id) { tour in
                        // 링크를 셀 뒤에 겹쳐 깐다 — NavigationLink의 label로 감싸면 List가 기본
                        // disclosure chevron을 붙여 셀의 커스텀 chevron과 겹치고 카드 폭도 줄어든다.
                        // 링크가 셀 크기로 늘어나 카드 전체가 탭 영역이 된다.
                        ZStack {
                            NavigationLink {
                                HistoryDetailFeatureBuilder.assemble(
                                    container: container,
                                    tourId: tour.id
                                )
                            } label: {
                                Color.clear
                                    .contentShape(Rectangle())
                            }
                            .opacity(0)
                            // 링크 라벨이 투명 Color라 VoiceOver가 읽을 내용이 없다 —
                            // 활성화 대상인 링크 자체에 카드 정보를 라벨로 준다
                            .accessibilityLabel(accessibilityLabel(for: tour))

                            // 카드는 표시 전용 — 탭은 뒤의 링크가, 낭독은 링크 라벨이 담당
                            tourCell(tour)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        // 그림자(radius 8, y 2)가 행 경계에서 잘리지 않도록 여유를 둔다
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // 주행 기록은 복구할 수 없어 풀 스와이프 즉시 삭제는 막고 확인을 받는다
                            Button(role: .destructive) {
                                pendingDeletion = tour
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(sectionTitle(group.day))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
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

    /// 카드가 시각적으로 보여주는 정보를 한 문장으로 읽어준다 (배지는 축약 표기라 단위를 풀어 씀)
    private func accessibilityLabel(for tour: HistoryRecord) -> String {
        let distance = String(format: "%.1f킬로미터", tour.distance)
        let topSpeed = String(format: "최고 속도 시속 %.0f킬로미터", tour.topSpeed)
        let maxLean = String(format: "최대 뱅킹각 %.0f도", tour.maxLeanAngle)
        return [
            tour.tourName,
            formatDate(tour.createdAt),
            distance,
            formatDuration(tour.duration),
            topSpeed,
            maxLean
        ].joined(separator: ", ")
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
