//  SpeedAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface

final class SpeedAnalyzer {
    
    private enum ActiveSpeedEvent {
        case acceleration(start: LocationSnapshot)
        case deceleration(start: LocationSnapshot)
    }
    
    private var thresholds: TrackingThresholds

    private var activeEvent: ActiveSpeedEvent?
    
    private var movingTimeSeconds: TimeInterval = 0
    private var movingDistanceKm: Double = 0
    private var topSpeedKmh: Double = 0
    private var currentSpeedKmh: Double = 0
    
    private var snapshotBufferCount = 5
    private var recentSnapshots: [LocationSnapshot] = []
    
    init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    func updateSpeed(_ currentSnapshot: LocationSnapshot) -> SpeedAnalyzerResult {
        defer {
            recentSnapshots.append(currentSnapshot)
            if recentSnapshots.count > snapshotBufferCount {
                _ = recentSnapshots.removeFirst()
            }
        }
        
        var topSpeedUpdate: Double?
        
        currentSpeedKmh = currentSnapshot.speedKmh
        if currentSnapshot.speedKmh > topSpeedKmh {
            topSpeedKmh = currentSnapshot.speedKmh
            topSpeedUpdate = topSpeedKmh
        }
        
        // 가속도 계산: 넓은 윈도우(oldest)로 노이즈 스무딩
        guard let prevSnapshot = recentSnapshots.first else {
            return SpeedAnalyzerResult(topSpeedUpdated: topSpeedUpdate)
        }
        let deltaTime = currentSnapshot.location.timestamp.timeIntervalSince(prevSnapshot.timestamp)
        guard deltaTime > 0 else {
            return SpeedAnalyzerResult(topSpeedUpdated: topSpeedUpdate)
        }
        
        let accel = calculateAcceleration(
            current: currentSnapshot,
            previous: prevSnapshot,
            deltaTime: deltaTime
        )
        
        let event = processSpeedEvents(
            accel: accel,
            current: currentSnapshot,
            previous: prevSnapshot,
            location: currentSnapshot.location
        )
        
        // 거리/시간 계산: 직전 스냅샷(last) 기준 — first 사용 시 5배 과산정 발생
        if let lastSnapshot = recentSnapshots.last {
            let statsDeltaTime = currentSnapshot.location.timestamp.timeIntervalSince(lastSnapshot.timestamp)
            if statsDeltaTime > 0 {
                updateMovingStats(speed: currentSnapshot.speedKmh, deltaTime: statsDeltaTime)
            }
        }
        
        return SpeedAnalyzerResult(topSpeedUpdated: topSpeedUpdate, event: event)
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateAcceleration(
        current: LocationSnapshot,
        previous: LocationSnapshot,
        deltaTime: TimeInterval
    ) -> Double {
        let deltaSpeed = current.speedKmh - previous.speedKmh
        return deltaSpeed / deltaTime
    }
    
    private func processSpeedEvents(
        accel: Double,
        current: LocationSnapshot,
        previous: LocationSnapshot,
        location: Location
    ) -> TrackingEvent? {
        var events: TrackingEvent?
        
        switch activeEvent {
        case nil:
            handleNoActiveEvent(accel: accel, previous: previous)
            
        case .acceleration(let startSpeedData):
            events = handleAccelerationEvent(
                accel: accel,
                start: startSpeedData,
                current: current,
                previous: previous,
                location: location
            )
            
        case .deceleration(let startSpeedData):
            events = handleDecelerationEvent(
                accel: accel,
                start: startSpeedData,
                current: current,
                previous: previous,
                location: location
            )
        }
        
        return events
    }
    
    private func handleNoActiveEvent(accel: Double, previous: LocationSnapshot) {
        if accel >= thresholds.accelerationKmhPerSec {
            activeEvent = .acceleration(start: previous)
        } else if accel <= -thresholds.decelerationKmhPerSec {
            activeEvent = .deceleration(start: previous)
        }
    }
    
    private func handleAccelerationEvent(
        accel: Double,
        start: LocationSnapshot,
        current: LocationSnapshot,
        previous: LocationSnapshot,
        location: Location
    ) -> TrackingEvent? {
        
        let shouldEndAcceleration = accel < thresholds.accelerationKmhPerSec
        let shouldTransitionToDeceleration = accel <= -thresholds.decelerationKmhPerSec
        
        guard shouldEndAcceleration ||
                shouldTransitionToDeceleration else { return nil }
        
        if shouldEndAcceleration {
            activeEvent = nil
        }
        
        if shouldTransitionToDeceleration {
            activeEvent = .deceleration(start: previous)
        }
        
        return makeSpeedChangeEvent(
            type: .rapidAcceleration,
            start: start,
            end: current,
            location: location
        )
    }
    
    private func handleDecelerationEvent(
        accel: Double,
        start: LocationSnapshot,
        current: LocationSnapshot,
        previous: LocationSnapshot,
        location: Location
    ) -> TrackingEvent? {
        
        let shouldEndDeceleration = accel > -thresholds.decelerationKmhPerSec
        let shouldTransitionToAcceleration = accel >= thresholds.accelerationKmhPerSec
        
        guard shouldEndDeceleration ||
                shouldTransitionToAcceleration else { return nil }
        
        if shouldEndDeceleration {
            activeEvent = nil
        }
        
        if shouldTransitionToAcceleration {
            activeEvent = .acceleration(start: previous)
        }
        
        return makeSpeedChangeEvent(
            type: .rapidDeceleration,
            start: start,
            end: current,
            location: location
        )
    }
    
    private func updateMovingStats(speed: Double, deltaTime: TimeInterval) {
        if speed >= thresholds.stopSpeedKmh {
            let secondsPerHour = 3600.0
            movingTimeSeconds += deltaTime
            movingDistanceKm += (speed * (deltaTime / secondsPerHour))
        }
    }
    
    func stats() -> TourStats {
        let averageSpeed: Double
        if movingTimeSeconds > 0 {
            let secondsPerHour = 3600.0
            averageSpeed = movingDistanceKm / (movingTimeSeconds / secondsPerHour)
        } else {
            averageSpeed = 0
        }
        return TourStats(
            movingTimeSeconds: movingTimeSeconds,
            movingDistanceKm: movingDistanceKm,
            averageSpeedKmh: averageSpeed
        )
    }
    
    func setThresholds(_ thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    /// 세션 복구 시 이전 누적값 시딩 — 이후 updateSpeed가 이 값에 이어서 누적한다
    func restoreStats(
        movingTimeSeconds: TimeInterval,
        movingDistanceKm: Double,
        topSpeedKmh: Double
    ) {
        self.movingTimeSeconds = movingTimeSeconds
        self.movingDistanceKm = movingDistanceKm
        self.topSpeedKmh = topSpeedKmh
    }

    func reset() {
        recentSnapshots = []
        movingTimeSeconds = 0
        movingDistanceKm = 0
        activeEvent = nil
        topSpeedKmh = 0
        currentSpeedKmh = 0
    }
    
    func handlePause() {
        recentSnapshots.removeAll()
        activeEvent = nil
        currentSpeedKmh = 0
    }
    
    func makeSpeedChangeEvent(
        type: TrackingEventType,
        start: LocationSnapshot,
        end: LocationSnapshot,
        location: Location
    ) -> TrackingEvent? {
        let duration = end.timestamp.timeIntervalSince(start.timestamp)
        guard duration > 0 else { return nil }
        return TrackingEvent(
            type: type,
            startTimestamp: start.timestamp,
            endTimestamp: end.timestamp,
            startSpeedKmh: start.speedKmh,
            endSpeedKmh: end.speedKmh,
            durationSeconds: duration,
            location: location
        )
    }
    
    // MARK: - Getters
    
    func currentSpeed() -> Double {
        currentSpeedKmh
    }
    
    func topSpeed() -> Double {
        topSpeedKmh
    }
    
}
