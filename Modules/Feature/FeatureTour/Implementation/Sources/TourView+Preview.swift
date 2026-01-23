//  TourView+Preview.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/21.
//

#if DEBUG
import SwiftUI
import FeatureTourInterface
import CoreSensorsInterface
import CoreTrackingInterface
import CoreLocation

private final class PreviewSensors: CoreSensorsInterface {
    func requestWhenInUseAuthorization() {}
    func requestAlwaysAuthorization() {}
    func start() {}
    func stop() {}
    
    func locationStream() -> AsyncStream<Location> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    
    func motionStream() -> AsyncStream<Motion> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private final class PreviewAnalyzer: TrackingAnalyzerInterface {
    func updateSpeed(_ data: SpeedData) -> [SpeedChangeEvent] { [] }
    func updateLeanAngle(_ data: LeanAngleData) -> [TrackingEvent] { [] }
    func updateAttitude(_ data: AttitudeData) -> [TrackingEvent] { [] }
    func updateAcceleration(_ data: AccelerationData) {}
    func mapEventsToLocations(_ events: [TrackingEvent]) -> [TrackingEventLocation] {
        events.map { TrackingEventLocation(event: $0, location: nil) }
    }
    func mapSpeedEventsToLocations(_ events: [SpeedChangeEvent]) -> [SpeedChangeEventLocation] {
        events.map { SpeedChangeEventLocation(event: $0, location: nil) }
    }
    func recordLocation(_ data: TrackingData) {}
    func route() -> [TrackingData] { [] }
    func stats() -> TourStats { TourStats(movingTimeSeconds: 0, movingDistanceKm: 0, averageSpeedKmh: 0) }
    func setThresholds(_ thresholds: TrackingThresholds) {}
    func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double) {}
    func reset() {}
}

struct TourView_Previews: PreviewProvider {
    static var previews: some View {
        let routeCoordinates = [
            CLLocationCoordinate2D(latitude: 37.553306, longitude: 127.237872),
            CLLocationCoordinate2D(latitude: 37.791396, longitude: 127.643504),
            CLLocationCoordinate2D(latitude: 37.676118, longitude: 127.622962),
            CLLocationCoordinate2D(latitude: 37.804599, longitude: 127.707569),
            CLLocationCoordinate2D(latitude: 37.806162, longitude: 127.772088),
            CLLocationCoordinate2D(latitude: 37.527303, longitude: 127.911991),
            CLLocationCoordinate2D(latitude: 37.508819, longitude: 127.424926)
        ]
        TourView(
            store: TourStore(
                dependencies: TourDependencies(
                    sensors: PreviewSensors(),
                    analyzer: PreviewAnalyzer()
                )
            ),
            routeCoordinates: routeCoordinates
        )
    }
}
#endif
