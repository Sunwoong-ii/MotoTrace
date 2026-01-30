//  RidingStore.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/21.
//

import SwiftUI
import CoreSensorsInterface
import CoreTrackingInterface
import CoreDataStorageInterface
import FeatureTourInterface

@MainActor
internal final class TourStore: ObservableObject {
    @Published private(set) var state: TourState
    
    private let sensors: CoreSensorsInterface
    private let analyzer: TrackingAnalyzerInterface
    private let repository: TourRepositoryInterface
    private var locationTask: Task<Void, Never>?
    private var motionTask: Task<Void, Never>?
    private var statsUpdateTask: Task<Void, Never>?
    
    private var currentTourId: UUID?
    
    internal init(
        sensors: CoreSensorsInterface,
        analyzer: TrackingAnalyzerInterface,
        repository: TourRepositoryInterface,
        initialState: TourState = TourState()
    ) {
        self.sensors = sensors
        self.analyzer = analyzer
        self.repository = repository
        self.state = initialState
    }
    
    internal func send(_ intent: TourIntent) {
        switch intent {
        case .startTracking:
            startTracking()
        case .stopTracking:
            stopTracking()
        }
    }
}

private extension TourStore {
    func startTracking() {
        guard locationTask == nil, motionTask == nil else { return }
        state.trackingStatus = .tracking
        
        // Create new tour
        let tourId = UUID()
        currentTourId = tourId
        
        let tourDTO = TourRecordDTO(
            id: tourId,
            tourName: "투어 \(Date().formatted(date: .abbreviated, time: .shortened))"
        )
        
        Task {
            try? await repository.createTour(tourDTO)
        }
        
        analyzer.startTour(tourId: tourId)
        
        sensors.requestWhenInUseAuthorization()
        sensors.start()
        
        // Start periodic stats update (every 1 second)
        statsUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await self?.updateStats()
            }
        }
        
        locationTask = Task { [weak self] in
            guard let self else { return }
            for await location in sensors.speedLocationStream() {
                // Update GPS status
                let accuracy = location.horizontalAccuracy
                if accuracy < 0 {
                    state.gpsStatus = "GPS 없음"
                } else if accuracy <= 10 {
                    state.gpsStatus = "GPS 양호"
                } else if accuracy <= 50 {
                    state.gpsStatus = "GPS 보통"
                } else {
                    state.gpsStatus = "GPS 약함"
                }
                
//                let trackingData = TrackingSpeedData(
//                    timestamp: location.timestamp,
//                    latitude: location.latitude,
//                    longitude: location.longitude,
//                    speed: location.speedKmh
//                )
                
                // Record location (saves to repository)
//                try? await analyzer.recordLocation(trackingData)
                
                // Update speed and get events (saves events to repository)
                let locationModel = Location(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    timestamp: location.timestamp
                )
                let speedEvents = try? await analyzer.updateSpeed(
                    SpeedData(timestamp: location.timestamp, speedKmh: location.speedKmh),
                    location: locationModel
                )
                
                // Update live stats in state
                state.liveStats = LiveStats(
                    speed: String(format: "%.0f", analyzer.currentSpeed()),
                    leanAngle: String(format: "%.1f", analyzer.currentLeanAngle()),
                    location: locationModel,
                    distance: state.liveStats.distance,
                    duration: state.liveStats.duration,
                    avgSpeed: state.liveStats.avgSpeed
                )
                
                // Update top speed
                state.topSpeed = String(format: "%.0f", analyzer.topSpeed())
            }
        }
        
        motionTask = Task { [weak self] in
            guard let self else { return }
            for await motion in sensors.motionStream() {
                let attitudeData = TrackingAttitudeData(
                    timestamp: motion.timestamp,
                    rollDegrees: motion.rollDegrees,
                    pitchDegrees: motion.pitchDegrees,
                    userAccelerationX: motion.userAccelerationX,
                    userAccelerationY: motion.userAccelerationY,
                    userAccelerationZ: motion.userAccelerationZ
                )
                
                analyzer.updateAcceleration(data: attitudeData)
                
                // Update attitude and get lean angle events (saves to repository)
                let events = try? await analyzer.updateAttitude(attitudeData)
                
                // Update live lean angle in state
                state.liveStats = LiveStats(
                    speed: state.liveStats.speed,
                    leanAngle: String(format: "%.1f", analyzer.currentLeanAngle()),
                    location: state.liveStats.location,
                    distance: state.liveStats.distance,
                    duration: state.liveStats.duration,
                    avgSpeed: state.liveStats.avgSpeed
                )
                
                // Update top lean angle
                state.topLeanAngle = String(format: "%.1f", abs(analyzer.topLeanAngle()))
            }
        }
    }
    
    func stopTracking() {
        state.trackingStatus = .idle
        sensors.stop()
        
        // Cancel all tasks
        locationTask?.cancel()
        motionTask?.cancel()
        statsUpdateTask?.cancel()
        locationTask = nil
        motionTask = nil
        statsUpdateTask = nil
        
        // Finish tour
        Task {
            try? await analyzer.finishTour()
            
            // Update final stats
            if let tourId = currentTourId {
                let stats = analyzer.stats()
                try? await repository.updateTourStats(
                    id: tourId,
                    duration: stats.movingTimeSeconds,
                    distance: stats.movingDistanceKm,
                    avgSpeed: stats.averageSpeedKmh,
                    topSpeed: analyzer.topSpeed(),
                    maxLeanAngle: abs(analyzer.topLeanAngle())
                )
            }
            
            currentTourId = nil
        }
    }
    
    func updateStats() {
        guard currentTourId != nil else { return }
        
        let stats = analyzer.stats()
        
        // Format duration
        let hours = Int(stats.movingTimeSeconds) / 3600
        let minutes = (Int(stats.movingTimeSeconds) % 3600) / 60
        let seconds = Int(stats.movingTimeSeconds) % 60
        let durationString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        // Update state
        state.liveStats = LiveStats(
            speed: state.liveStats.speed,
            leanAngle: state.liveStats.leanAngle,
            location: state.liveStats.location,
            distance: String(format: "%.2f", stats.movingDistanceKm),
            duration: durationString,
            avgSpeed: String(format: "%.0f", stats.averageSpeedKmh)
        )
        
        // Update repository periodically
        if let tourId = currentTourId {
            Task {
                try? await repository.updateTourStats(
                    id: tourId,
                    duration: stats.movingTimeSeconds,
                    distance: stats.movingDistanceKm,
                    avgSpeed: stats.averageSpeedKmh,
                    topSpeed: analyzer.topSpeed(),
                    maxLeanAngle: abs(analyzer.topLeanAngle())
                )
            }
        }
    }
}
