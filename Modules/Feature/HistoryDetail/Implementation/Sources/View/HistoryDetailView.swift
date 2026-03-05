import SwiftUI
import MapKit
import HistoryDetailInterface

struct HistoryDetailView: View {
    @StateObject private var store: HistoryDetailStore
    @State private var cameraPosition: MapCameraPosition = .automatic
    @Environment(\.dismiss) private var dismiss
    
    init(store: HistoryDetailStore) {
        _store = StateObject(wrappedValue: store)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 바
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            Spacer()
            
            // 하단 통계 패널
            statsPanel
        }
        .background {
            Map(position: $cameraPosition) {
                // 경로 폴리라인
                if store.state.routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: store.state.routeCoordinates)
                        .stroke(.blue, lineWidth: 4)
                }
                
                // 시작점
                if let first = store.state.routeCoordinates.first {
                    Annotation("출발", coordinate: first) {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
                
                // 도착점
                if let last = store.state.routeCoordinates.last,
                   store.state.routeCoordinates.count > 1 {
                    Annotation("도착", coordinate: last) {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls { }
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            store.send(.loadTour)
        }
    }
}

// MARK: - Top Bar

private extension HistoryDetailView {
    var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(store.state.tourName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(formatDate(store.state.createdAt))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            // 좌우 균형용
            Color.clear
                .frame(width: 40, height: 40)
        }
    }
}

// MARK: - Stats Panel

private extension HistoryDetailView {
    var statsPanel: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
            
            // 상단 2열
            HStack(spacing: 0) {
                statItem(label: "DISTANCE", value: String(format: "%.1f", store.state.distance), unit: "km")
                Divider().frame(height: 40)
                statItem(label: "DURATION", value: formatDuration(store.state.duration), unit: "")
            }
            
            Divider()
            
            // 하단 3열
            HStack(spacing: 0) {
                statItem(label: "AVG SPEED", value: String(format: "%.0f", store.state.avgSpeed), unit: "km/h")
                Divider().frame(height: 40)
                statItem(label: "TOP SPEED", value: String(format: "%.0f", store.state.topSpeed), unit: "km/h")
                Divider().frame(height: 40)
                statItem(label: "MAX LEAN", value: String(format: "%.1f", store.state.maxLeanAngle), unit: "°")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(
            Color(.systemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 20, y: -4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
    }
    
    func statItem(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Formatters

private extension HistoryDetailView {
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd  HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
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
