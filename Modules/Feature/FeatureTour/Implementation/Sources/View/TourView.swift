//
//  TourView.swift
//  FeatureTour
//
//  Created by Woong on 2026/01/21.
//

import SwiftUI
import MapKit
import FeatureTourInterface
import CoreLocation
import CoreTrackingInterface

/// 라이딩 트래킹 화면
internal struct TourView: View {
    @StateObject private var store: TourStore
    @State private var cameraPosition: MapCameraPosition
    @State private var showNameInput = false
    @State private var tourNameInput = ""
    
    private var isActive: Bool {
        store.state.trackingStatus != .idle
    }
    
    internal init(store: TourStore) {
        _store = StateObject(wrappedValue: store)
        _cameraPosition = State(initialValue: .userLocation(
            followsHeading: true,
            fallback: .automatic
        ))
    }
    
    internal var body: some View {
        VStack(spacing: 0) {
            if isActive {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                HStack {
                    gauges
                        .padding(.leading, 16)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    
                    Spacer()
                }
            }

            Spacer()
            
            VStack(spacing: 12) {
                currentPositionButton
                
                bottomContent
            }
        }
        // Map을 background로 — safe area 무시하여 전체 화면 채움
        .background {
            Map(position: $cameraPosition) {
                // mapSessionId가 바뀔 때마다 컨텐츠 전체를 재생성 → MapPolyline 캐시 제거
                let sessionId = store.state.mapSessionId
                UserAnnotation()
                    .tag(sessionId)
                
                if store.state.routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: store.state.routeCoordinates)
                        .stroke(.blue, lineWidth: 4)
                        .tag(sessionId)
                }
            }
            .mapStyle(.standard)
            .mapControls { }
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.35), value: isActive)
        .onChange(of: store.state.routeCoordinates.count) { _, _ in
            updateCamera()
        }
        .onChange(of: isActive) { _, active in
            if active {
                updateCamera()
            } else {
                withAnimation(.easeInOut(duration: 0.35)) {
                    cameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
                }
            }
        }
        .task {
            // idle 상태일 때만 시도 — 앱이 정상 실행된 경우엔 sessionStore.load()가 nil을 반환해 무시됨
            if store.state.trackingStatus == .idle {
                store.send(.restoreTracking)
            }
        }
        .alert("투어 이름", isPresented: $showNameInput) {
            TextField("예: 북한산 라이딩", text: $tourNameInput)
            Button("시작") {
                let name = tourNameInput.trimmingCharacters(in: .whitespaces)
                let finalName = name.isEmpty
                    ? "투어 \(Date().formatted(date: .abbreviated, time: .shortened))"
                    : name
                store.send(.startTracking(tourName: finalName))
                tourNameInput = ""
            }
            Button("취소", role: .cancel) {
                tourNameInput = ""
            }
        } message: {
            Text("기록할 투어의 이름을 입력하세요")
        }
    }
}

// MARK: - Top Bar

private extension TourView {
    var topBar: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 4) {
                Text(store.state.tourName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(TourDesign.textPrimary)
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(gpsColor)
                        .frame(width: 7, height: 7)
                    Text(store.state.gpsStatus)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TourDesign.textSecondary)
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(.ultraThinMaterial))
            }
            
            Spacer()
        }
    }
    
    var gpsColor: Color {
        switch store.state.gpsStatus {
        case "GPS 양호": TourDesign.gpsGreen
        case "GPS 보통": .orange
        case "GPS 약함": .red
        default: TourDesign.textSecondary
        }
    }
    
    /// 트래킹 중 카메라 업데이트
    /// 하단 패널(약 220pt)이 올라오거나 위치가 변경되면
    /// 카메라 중심을 실제 위치보다 남쪽으로 오프셋시켜 마커가 화면 위쪽에 표시됨
    func updateCamera() {
        guard isActive else { return }
        let loc = store.state.liveStats.location
        guard loc.latitude != 0 || loc.longitude != 0 else { return }
        
        // 오프셋: 카메라 400m 거리에서 화면 약 40% 아래로 중심 이동 (≈ 160m ≈ 0.00144°)
        // → 사용자 마커가 화면 상단 60% 지점에 나타나 하단 패널과 갹치지 않음
        let latOffset = 0.00144
        let center = CLLocationCoordinate2D(
            latitude: loc.latitude - latOffset,
            longitude: loc.longitude
        )
        withAnimation(.easeOut(duration: 0.3)) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: center,
                distance: 400,
                heading: 0,
                pitch: 0
            ))
        }
    }
}

// MARK: - Right Map Controls

private extension TourView {
    var currentPositionButton: some View {
        Button {
            cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                Text("현재 위치로")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(TourDesign.primaryBlue)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }
}

// MARK: - Left Gauges (Tracking)

private extension TourView {
    var gauges: some View {
        VStack(alignment: .leading, spacing: 10) {
            SpeedGaugeView(speed: store.state.liveStats.speed, maxSpeed: 200)
            LeanAngleView(angle: store.state.liveStats.leanAngle)
            InclinationView(inclination: store.state.liveStats.inclination)
        }
    }
}

// MARK: - Bottom

private extension TourView {
    var bottomContent: some View {
        Group {
            if store.state.trackingStatus == .tracking {
                TourStatView(
                    duration: store.state.liveStats.duration,
                    distance: store.state.liveStats.distance,
                    avgSpeed: store.state.liveStats.avgSpeed,
                    topSpeed: store.state.topSpeed,
                    topLeanAngle: store.state.topLeanAngle,
                    trackingStatus: .tracking,
                    onPause: { store.send(.pauseTracking) },
                    onStop: { store.send(.stopTracking) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            } else if store.state.trackingStatus == .paused {
                TourStatView(
                    duration: store.state.liveStats.duration,
                    distance: store.state.liveStats.distance,
                    avgSpeed: store.state.liveStats.avgSpeed,
                    topSpeed: store.state.topSpeed,
                    topLeanAngle: store.state.topLeanAngle,
                    trackingStatus: .paused,
                    onPause: { store.send(.resumeTracking) },
                    onStop: { store.send(.stopTracking) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            } else {
                TrackingButton(status: .idle) {
                    showNameInput = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
