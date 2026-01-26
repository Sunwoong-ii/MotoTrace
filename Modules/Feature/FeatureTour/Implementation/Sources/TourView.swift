//  RidingStore.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/21.
//

import SwiftUI
import MapKit
import FeatureTourInterface
import CoreLocation

/// 라이딩 트래킹 화면
internal struct TourView: View {
    @StateObject private var store: TourStore
    private let routeCoordinates: [CLLocationCoordinate2D]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var cameraPosition: MapCameraPosition
    
    internal init(
        store: TourStore,
        routeCoordinates: [CLLocationCoordinate2D] = []
    ) {
        _store = StateObject(wrappedValue: store)
        self.routeCoordinates = routeCoordinates
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }
    
    internal var body: some View {
        Map(position: $cameraPosition) {
            Marker("Start", coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780))
            if !routeCoordinates.isEmpty {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(.blue, lineWidth: 4)
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Button(action: zoomIn) {
                    Image(systemName: "plus.magnifyingglass")
                        .padding(8)
                }
                Button(action: zoomOut) {
                    Image(systemName: "minus.magnifyingglass")
                        .padding(8)
                }
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(12)
        }
        .overlay(alignment: .bottom) {
            TourStatView()
                .frame(height: 250)
                .padding([.horizontal, .bottom], 10)
                
                
        }
        .onAppear { store.send(.startTracking) }
        .onDisappear { store.send(.stopTracking) }
    }
}

private extension TourView {
    func zoomIn() {
        let minSpan = 0.001
        let zoomInFactor = 0.6
        region.span = MKCoordinateSpan(
            latitudeDelta: max(region.span.latitudeDelta * zoomInFactor, minSpan),
            longitudeDelta: max(region.span.longitudeDelta * zoomInFactor, minSpan)
        )
        cameraPosition = .region(region)
    }
    
    func zoomOut() {
        let maxSpan = 10.0
        let zoomOutFactor = 1.6
        region.span = MKCoordinateSpan(
            latitudeDelta: min(region.span.latitudeDelta * zoomOutFactor, maxSpan),
            longitudeDelta: min(region.span.longitudeDelta * zoomOutFactor, maxSpan)
        )
        cameraPosition = .region(region)
    }
}

