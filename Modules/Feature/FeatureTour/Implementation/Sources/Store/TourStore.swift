//  TourStore.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/21.
//

import SwiftUI
import CoreSensorsInterface
import CoreTrackingInterface
import CoreDataStorageInterface
import FeatureTourInterface
import CoreLocation

@MainActor
final class TourStore: ObservableObject {
    @Published private(set) var state: TourState
    
    private let sensors: CoreSensorsInterface
    private let analyzer: TrackingAnalyzerInterface
    private let repository: TourRepositoryInterface
    private var locationTask: Task<Void, Never>?
    private var motionTask: Task<Void, Never>?
    private var statsUpdateTask: Task<Void, Never>?
    
    private var currentTourId: UUID?
    private var tourStartDate: Date?
    private var pausedAt: Date?
    
    init(
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
    
    func send(_ intent: TourIntent) {
        switch intent {
        case .startTracking(let tourName):
            startTracking(tourName: tourName)
        case .pauseTracking:
            pauseTracking()
        case .resumeTracking:
            resumeTracking()
        case .stopTracking:
            stopTracking()
        }
    }

    private func startTracking(tourName: String) {
        guard locationTask == nil, motionTask == nil else { return }
        state.trackingStatus = .tracking
        state.tourName = tourName
        
        // Create new tour
        let tourId = UUID()
        currentTourId = tourId
        tourStartDate = Date()
        
        let tourDTO = TourRecordDTO(
            id: tourId,
            tourName: tourName
        )
        
        Task {
            try? await repository.createTour(tourDTO)
        }
        
        analyzer.reset()
        state.routeCoordinates.removeAll()
        
        sensors.requestWhenInUseAuthorization()
        sensors.start()
        
        // Start periodic stats update (every 1 second)
        statsUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await self?.updateStats()
            }
        }
        
        startSensorTasks(tourId: tourId)
    }
    
    private func pauseTracking() {
        state.trackingStatus = .paused
        pausedAt = Date()
        sensors.stop()
        
        locationTask?.cancel()
        motionTask?.cancel()
        statsUpdateTask?.cancel()
        locationTask = nil
        motionTask = nil
        statsUpdateTask = nil
    }
    
    private func resumeTracking() {
        guard let tourId = currentTourId else { return }
        state.trackingStatus = .tracking
        
        // pause 시간만큼 시작 시점을 밀어서 경과 시간에서 제외
        if let pauseStart = pausedAt {
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            tourStartDate = tourStartDate?.addingTimeInterval(pauseDuration)
            pausedAt = nil
        }
        
        sensors.start()
        
        statsUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await self?.updateStats()
            }
        }
        
        startSensorTasks(tourId: tourId)
    }
    
    private func stopTracking() {
        state.trackingStatus = .idle
        sensors.stop()
        
        // Cancel all tasks
        locationTask?.cancel()
        motionTask?.cancel()
        statsUpdateTask?.cancel()
        locationTask = nil
        motionTask = nil
        statsUpdateTask = nil
        
        // Finish tour — 최종 통계 저장
        Task {
            guard let tourId = currentTourId else { return }
            
            let elapsed = Date().timeIntervalSince(tourStartDate ?? Date())
            let stats = analyzer.stats()
            try? await repository.updateTripStats(
                id: tourId,
                tripStats: TripStats(
                    duration: elapsed,
                    distance: stats.movingDistanceKm,
                    avgSpeed: stats.averageSpeedKmh
                )
            )
            try? await repository.updateTopSpeed(id: tourId, speed: analyzer.topSpeed())
            try? await repository.updateTopLeanAngle(id: tourId, leanAngle: abs(analyzer.topLeanAngle()))
            try? await repository.finishTour(id: tourId)
            
            currentTourId = nil
            tourStartDate = nil
        }
    }
    
    private func startSensorTasks(tourId: UUID) {
        locationTask = Task { [weak self] in
            guard let self else { return }
            for await location in sensors.speedLocationStream() {
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
                
                let locationModel = Location(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    timestamp: location.timestamp
                )
                
                let snapshot = LocationSnapshot(
                    timestamp: location.timestamp,
                    speedKmh: location.speedKmh,
                    location: locationModel
                )
                
                analyzer.updateLocation(snapshot)
                let speedResult = analyzer.updateSpeed(snapshot)
                
                await saveSpeedResult(speedResult, tourId: tourId)
                await saveLocation(snapshot, tourId: tourId)
                
                state.liveStats = LiveStats(
                    speed: String(format: "%.0f", analyzer.currentSpeed()),
                    leanAngle: state.liveStats.leanAngle,
                    location: locationModel,
                    distance: state.liveStats.distance,
                    duration: state.liveStats.duration,
                    avgSpeed: state.liveStats.avgSpeed
                )
                state.routeCoordinates.append(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                state.topSpeed = String(format: "%.0f", analyzer.topSpeed())
            }
        }
        
        motionTask = Task { [weak self] in
            guard let self else { return }
            for await motion in sensors.motionStream() {
                let attitudeData = MotionSnapshot(
                    timestamp: motion.timestamp,
                    rollDegrees: motion.rollDegrees,
                    pitchDegrees: motion.pitchDegrees,
                    userAccelerationX: motion.userAccelerationX,
                    userAccelerationY: motion.userAccelerationY,
                    userAccelerationZ: motion.userAccelerationZ
                )
                
                analyzer.updateAcceleration(attitudeData)
                let leanResult = analyzer.updateAttitude(attitudeData)
                await saveLeanResult(leanResult, tourId: tourId)
                
                state.liveStats = LiveStats(
                    speed: state.liveStats.speed,
                    leanAngle: "\(analyzer.currentLeanAngle())",
                    location: state.liveStats.location,
                    distance: state.liveStats.distance,
                    duration: state.liveStats.duration,
                    avgSpeed: state.liveStats.avgSpeed
                )
                state.topLeanAngle = String(format: "%.1f", abs(analyzer.topLeanAngle()))
            }
        }
    }
    
    private func updateStats() {
        guard let tourId = currentTourId else { return }
        
        let stats = analyzer.stats()
        
        // 경과 시간: 시작 시점 - 현재 시간
        let elapsed = Date().timeIntervalSince(tourStartDate ?? Date())
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
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
        Task {
            try? await repository.updateTripStats(
                id: tourId,
                tripStats: TripStats(
                    duration: elapsed,
                    distance: stats.movingDistanceKm,
                    avgSpeed: stats.averageSpeedKmh
                )
            )
        }
    }
    
    // MARK: - Repository Save Helpers
    
    private func saveSpeedResult(_ result: SpeedAnalyzerResult, tourId: UUID) async {
        if let topSpeed = result.topSpeedUpdated {
            try? await repository.updateTopSpeed(id: tourId, speed: topSpeed)
        }
        
        if let event = result.event {
            try? await repository.addEvent(toEventDTO(event), to: tourId)
        }
    }
    
    private func saveLeanResult(_ result: LeanAnalyzerResult, tourId: UUID) async {
        if let maxLean = result.maxLeanAngleUpdated {
            try? await repository.updateTopLeanAngle(id: tourId, leanAngle: maxLean)
        }
        
        if let event = result.event {
            try? await repository.addEvent(toEventDTO(event), to: tourId)
        }
    }
    
    private func saveLocation(_ data: LocationSnapshot, tourId: UUID) async {
        let locationDTO = LocationPointDTO(
            latitude: data.location.latitude,
            longitude: data.location.longitude,
            timestamp: data.location.timestamp,
            speed: data.speedKmh
        )
        try? await repository.addLocation(locationDTO, to: tourId)
    }
    
    private func toEventDTO(_ event: TrackingEvent) -> TourEventDTO {
        TourEventDTO(
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
}
