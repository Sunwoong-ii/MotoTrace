//  TrackingAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface
import CoreDataStorageInterface

enum SpeedEvent {
    case maxSpeedUpdated(Double)
    case rapidAcceleration(TrackingEvent)
    case rapidDeceleration(TrackingEvent)
}

final class TrackingAnalyzer: TrackingAnalyzerInterface {
    private var thresholds: TrackingThresholds
    private var speedAnalyzer: SpeedAnalyzer
    private var leanAnalyzer: LeanAnalyzer
    private var recentLocation: LocationSnapshot?
    
    // Repository integration
    private let repository: TourRepositoryInterface
    private var currentTourId: UUID?
    
    init(thresholds: TrackingThresholds, repository: TourRepositoryInterface) {
        self.thresholds = thresholds
        self.speedAnalyzer = SpeedAnalyzer(thresholds: thresholds)
        self.leanAnalyzer = LeanAnalyzer(thresholds: thresholds)
        self.repository = repository
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
    
    func updateSpeed(_ data: LocationSnapshot) async throws -> TrackingEvent? {
        let result = speedAnalyzer.updateSpeed(data)
        try await saveSpeedEvent(result)
        
        return result.event
    }
    
    func updateAttitude(_ data: MotionSnapshot) async throws -> TrackingEvent? {
        guard let recentLocation else { return nil }
        let result = leanAnalyzer.updateAttitude(data, locationSnapshot: recentLocation)
        try await
        saveLeanEvent(result)
        
        return result.event
    }
    
    func updateAcceleration(_ data: MotionSnapshot) {
        speedAnalyzer.updateAcceleration(data)
    }
    
    func recordLocation(_ data: LocationSnapshot) async throws {
        recentLocation = data
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
        recentLocation = nil
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
    // MARK: - Repository Save Helpers
    
    func toDTO(event: TrackingEvent) -> TourEventDTO {
        return TourEventDTO(
            type: event.type.rawValue,
            startTime: event.startTimestamp,
            endTime: event.endTimestamp,
            startSpeed: event.startSpeedKmh,
            endSpeed: event.endSpeedKmh,
            latitude: event.location.latitude,
            longitude: event.location.longitude,
            leanAngle: event.leanAngle
        )
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
    
    private func saveLeanEvent(_ event: LeanAnalyzerResult) async throws {
        guard let currentTourId  else { return }
        
        if let maxLeanAngleUpdated = event.maxLeanAngleUpdated {
            try await repository.updateTopLeanAngle(id: currentTourId, leanAngle: maxLeanAngleUpdated)
        }
        
        if let event = event.event {
            try await repository.addEvent(toDTO(event: event), to: currentTourId)
        }
    }
    
    private func saveSpeedEvent(_ event: SpeedAnalyzerResult) async throws {
        guard let currentTourId  else { return }
        
        if let topSpeedUpdated = event.topSpeedUpdated {
            try await repository.updateTopSpeed(id: currentTourId, speed: topSpeedUpdated)
        }
        
        if let event = event.event {
            try await repository.addEvent(toDTO(event: event), to: currentTourId)
        }
    }
}
