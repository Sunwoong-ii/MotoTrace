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
        case .startTracking(let tourName):
            startTracking(tourName: tourName)
        case .stopTracking:
            stopTracking()
        }
    }
}

private extension TourStore {
    func startTracking(tourName: String) {
        guard locationTask == nil, motionTask == nil else { return }
        state.trackingStatus = .tracking
        state.tourName = tourName
        
        // Create new tour
        let tourId = UUID()
        currentTourId = tourId
        
        let tourDTO = TourRecordDTO(
            id: tourId,
            tourName: tourName
        )
        
        Task {
            try? await repository.createTour(tourDTO)
        }
        
        analyzer.reset()
        
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
                
                // Analyzer에 위치 갱신 (린앵글 참조용)
                analyzer.updateLocation(snapshot)
                
                // 속도 분석 (결과만 반환)
                let speedResult = analyzer.updateSpeed(snapshot)
                
                // Repository 저장 (Store가 전담)
                await saveSpeedResult(speedResult, tourId: tourId)
                await saveLocation(snapshot, tourId: tourId)
                
                
                let stat = LiveStats(
                    speed: String(format: "%.0f", analyzer.currentSpeed()),
                    leanAngle: state.liveStats.leanAngle,
                    location: locationModel,
                    distance: state.liveStats.distance,
                    duration: state.liveStats.duration,
                    avgSpeed: state.liveStats.avgSpeed
                )
                
                state.liveStats = stat
                
                print("stat:: \(stat)")
                
                // Update top speed
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
                
                // 자세 분석 (결과만 반환)
                let leanResult = analyzer.updateAttitude(attitudeData)
                
                // Repository 저장 (Store가 전담)
                await saveLeanResult(leanResult, tourId: tourId)
                
                let stat = LiveStats(
                    speed: state.liveStats.speed,
                    leanAngle: "\(analyzer.currentLeanAngle())",
                    location: state.liveStats.location,
                    distance: state.liveStats.distance,
                    duration: state.liveStats.duration,
                    avgSpeed: state.liveStats.avgSpeed
                )
                state.liveStats = stat
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
        
        // Finish tour — 최종 통계 저장
        Task {
            guard let tourId = currentTourId else { return }
            
            let stats = analyzer.stats()
            try? await repository.updateTripStats(
                id: tourId,
                tripStats: TripStats(
                    duration: stats.movingTimeSeconds,
                    distance: stats.movingDistanceKm,
                    avgSpeed: stats.averageSpeedKmh
                )
            )
            try? await repository.updateTopSpeed(id: tourId, speed: analyzer.topSpeed())
            try? await repository.updateTopLeanAngle(id: tourId, leanAngle: abs(analyzer.topLeanAngle()))
            try? await repository.finishTour(id: tourId)
            
            currentTourId = nil
        }
    }
    
    func updateStats() {
        guard let tourId = currentTourId else { return }
        
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
        Task {
            try? await repository.updateTripStats(
                id: tourId,
                tripStats: TripStats(
                    duration: stats.movingTimeSeconds,
                    distance: stats.movingDistanceKm,
                    avgSpeed: stats.averageSpeedKmh
                )
            )
        }
    }
    
    // MARK: - Repository Save Helpers
    
    func saveSpeedResult(_ result: SpeedAnalyzerResult, tourId: UUID) async {
        if let topSpeed = result.topSpeedUpdated {
            try? await repository.updateTopSpeed(id: tourId, speed: topSpeed)
        }
        
        if let event = result.event {
            try? await repository.addEvent(toEventDTO(event), to: tourId)
        }
    }
    
    func saveLeanResult(_ result: LeanAnalyzerResult, tourId: UUID) async {
        if let maxLean = result.maxLeanAngleUpdated {
            try? await repository.updateTopLeanAngle(id: tourId, leanAngle: maxLean)
        }
        
        if let event = result.event {
            try? await repository.addEvent(toEventDTO(event), to: tourId)
        }
    }
    
    func saveLocation(_ data: LocationSnapshot, tourId: UUID) async {
        let locationDTO = LocationPointDTO(
            latitude: data.location.latitude,
            longitude: data.location.longitude,
            timestamp: data.location.timestamp,
            speed: data.speedKmh
        )
        try? await repository.addLocation(locationDTO, to: tourId)
    }
    
    func toEventDTO(_ event: TrackingEvent) -> TourEventDTO {
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
