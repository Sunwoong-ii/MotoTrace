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
import Shared

/// 라이딩 트래킹 화면
internal struct TourView: View {
    @StateObject private var store: TourStore
    @State private var cameraPosition: MapCameraPosition
    @State private var showNameInput = false
    @State private var tourNameInput = ""
    
    private var isActive: Bool {
        store.state.trackingStatus != .idle
    }

    /// Mock 센서 모드에서 카메라가 따라갈 좌표 — 시스템 위치는 가상 경로와 무관하므로 경로 끝을 쓴다
    private var mockCurrentCoordinate: CLLocationCoordinate2D? {
        guard LaunchFlags.useMockSensors, isActive else { return nil }
        return store.state.routeCoordinates.last
    }

    /// Mock 팔로우 카메라 줌 (미터)
    private static let mockFollowDistance: Double = 1200
    
    internal init(store: TourStore) {
        _store = StateObject(wrappedValue: store)
        // followsHeading: false — 지도는 항상 북쪽 고정(north-up). 헤딩 팔로우를 켜면
        // 폰 방향대로 지도가 회전해 기본 세팅(북쪽 고정)과 어긋난다
        _cameraPosition = State(initialValue: .userLocation(
            followsHeading: false,
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
                if let mockCoordinate = mockCurrentCoordinate {
                    // Mock 트래킹 중엔 시스템 위치(UserAnnotation)가 가상 경로와 무관 → 경로 끝에 마커 표시
                    Annotation("", coordinate: mockCoordinate) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 22, height: 22)
                            Circle()
                                .fill(TourDesign.primaryBlue)
                                .frame(width: 14, height: 14)
                        }
                        .shadow(color: .black.opacity(0.25), radius: 3)
                    }
                    .tag(sessionId)
                } else {
                    UserAnnotation()
                        .tag(sessionId)
                }

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
        // 트래킹 세션 중(일시정지 포함)에는 하단 탭바를 숨겨 몰입형 주행 화면을 확보 —
        // 일시정지도 세션 진행 중이라 탭바로 History 이탈이 열리지 않게 idle에서만 재등장
        .toolbar(isActive ? .hidden : .visible, for: .tabBar)
        .onChange(of: isActive) { _, active in
            guard !active else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
            }
        }
        .onChange(of: store.state.routeCoordinates.count) { _, _ in
            // Mock 모드 전용 팔로우 — 실 GPS는 .userLocation이 시스템 위치를 따라가므로 관여하지 않음
            // 사용자가 지도를 팬했으면(positionedByUser) 자동 팔로우를 멈춰 조작을 방해하지 않는다
            guard let mockCoordinate = mockCurrentCoordinate,
                  !cameraPosition.positionedByUser else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: mockCoordinate,
                    distance: Self.mockFollowDistance
                ))
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
}

// MARK: - Right Map Controls

private extension TourView {
    var currentPositionButton: some View {
        Button {
            if let mockCoordinate = mockCurrentCoordinate {
                // Mock 트래킹 중: 시스템 위치가 아닌 가상 경로 끝으로 센터링 (프로그램 설정 → 자동 팔로우 재개)
                withAnimation(.easeInOut(duration: 0.35)) {
                    cameraPosition = .camera(MapCamera(
                        centerCoordinate: mockCoordinate,
                        distance: Self.mockFollowDistance
                    ))
                }
            } else {
                cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
            }
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
        .accessibilityIdentifier("currentPositionButton")
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
                .accessibilityIdentifier("startRecordingButton")
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
