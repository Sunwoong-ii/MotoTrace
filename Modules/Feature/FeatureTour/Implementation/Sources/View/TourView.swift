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
                UserAnnotation()
                
                if store.state.routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: store.state.routeCoordinates)
                        .stroke(.blue, lineWidth: 4)
                }
            }
            .mapStyle(.standard)
            .mapControls { }
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.35), value: isActive)
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
            cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                Text("현재 위치로")
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
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
