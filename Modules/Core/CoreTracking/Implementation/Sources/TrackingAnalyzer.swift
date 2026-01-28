//  TrackingAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface
import CoreDataStorageInterface

enum LeanEvent {
    case maxLeanAngleUpdated(Double)
    case leanAngle(TrackingEvent)
}

enum SpeedEvent {
    case maxSpeedUpdated(Double)
    case rapidAcceleration(TrackingEvent)
    case rapidDeceleration(TrackingEvent)
}

final class TrackingAnalyzer: TrackingAnalyzerInterface {
    private let maxLocationBufferCount = 120
    private var thresholds: TrackingThresholds
    private var speedAnalyzer: SpeedAnalyzer
    private var leanAnalyzer: LeanAnalyzer
    private var recentLocations: [Location] = []
    
    // Repository integration
    private let repository: TourRepositoryInterface
    private var currentTourId: UUID?
    
     init(thresholds: TrackingThresholds, repository: TourRepositoryInterface) {
        self.thresholds = thresholds
        self.speedAnalyzer = SpeedAnalyzer(thresholds: thresholds)
        self.leanAnalyzer = LeanAnalyzer(thresholds: thresholds)
        self.repository = repository
    }
     
     
     private func setupCallback() {
         leanAnalyzer.onEvent = { [weak self] (event: LeanEvent) in
             switch event {
             case .maxLeanAngleUpdated(let double): break
             case .leanAngle(let trackingEvent): break
             }
         }
         
         speedAnalyzer.onEvent = { [weak self] (event: SpeedEvent) in
             switch event {
             case .maxSpeedUpdated(let double): break
             case .rapidAcceleration(let trackingEvent): break
             case .rapidDeceleration(let trackingEvent): break
             }
         }
     }
    
    // MARK: - Tour Lifecycle
    
     func startTour(tourId: UUID) {
        currentTourId = tourId
        reset()
    }
    
     func finishTour() async throws {
        guard let tourId = currentTourId else { return }
        try await repository.finishTour(id: tourId)
        currentTourId = nil
    }
    
    // MARK: - Data Updates
    
     func updateSpeed(_ data: LocationSnapshot, location: Location) async throws -> [TrackingEvent] {
        let events = speedAnalyzer.updateSpeed(data, location: location)
        try await saveSpeedEvents(events)
        return events
    }

     func updateAttitude(_ data: MotionSnapshot) async throws -> [TrackingEvent] {
        guard let recentLocation = recentLocations.last else { return [] }
        let events = leanAnalyzer.updateAttitude(data, location: recentLocation)
        try await saveLeanAngleEvents(events)
        return events
    }

     func updateAcceleration(_ data: MotionSnapshot) {
        speedAnalyzer.updateAcceleration(data)
    }
    
     func recordLocation(_ data: LocationSnapshot) async throws {
        recentLocations.append(data.location)
        trimLocationBuffer()
        try await saveLocation(data)
    }
    
    // MARK: - Stats & Configuration
    
     func stats() -> TourStats {
        speedAnalyzer.stats()
    }
    
     func setThresholds(_ thresholds: TrackingThresholds) {
        self.thresholds = thresholds
        speedAnalyzer.setThresholds(thresholds)
        leanAnalyzer.setThresholds(thresholds)
    }
    
     func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double) {
        leanAnalyzer.calibrateLeanZero(rollDegrees: rollDegrees, pitchDegrees: pitchDegrees)
    }
    
     func reset() {
        speedAnalyzer.reset()
        leanAnalyzer.reset()
        recentLocations.removeAll()
    }
    
    // MARK: - Real-time Data Getters
    
     func currentSpeed() -> Double {
        speedAnalyzer.currentSpeed()
    }
    
     func topSpeed() -> Double {
        speedAnalyzer.topSpeed()
    }
    
     func topLeanAngle() -> Double {
        leanAnalyzer.topLeanAngle()
    }

}

private extension TrackingAnalyzer {
    func trimLocationBuffer() {
        if recentLocations.count > maxLocationBufferCount {
            recentLocations.removeFirst(recentLocations.count - maxLocationBufferCount)
        }
    }
    
    // MARK: - Repository Save Helpers
    
    func saveSpeedEvents(_ events: [TrackingEvent]) async throws {
        guard let tourId = currentTourId else { return }
        
        for event in events {
            let eventDTO = TourEventDTO(
                type: event.type.rawValue,
                startTime: event.startTimestamp,
                endTime: event.endTimestamp,
                startSpeed: event.startSpeedKmh,
                endSpeed: event.endSpeedKmh,
                latitude: event.location.latitude,
                longitude: event.location.longitude
            )
            try await repository.addEvent(eventDTO, to: tourId)
        }
    }
    
    func saveLeanAngleEvents(_ events: TrackingEvent) async throws {
        guard let tourId = currentTourId, let location = recentLocations.last else { return }
        
        let eventDTO = TourEventDTO(
            type: event.type.rawValue,
            startTime: location.timestamp,
            endTime: nil,
            startSpeed: speedAnalyzer.currentSpeed(),
            endSpeed: nil,
            latitude: location.latitude,
            longitude: location.longitude
        )
        try await repository.addEvent(eventDTO, to: tourId)
        
    }
    
    func saveLocation(_ data: LocationSnapshot) async throws {
        guard let tourId = currentTourId else { return }
        
        let locationDTO = LocationPointDTO(
            latitude: data.location.latitude,
            longitude: data.location.longitude,
            timestamp: data.location.timestamp,
            speed: data.speedKmh
        )
        try await repository.addLocation(locationDTO, to: tourId)
    }
}
