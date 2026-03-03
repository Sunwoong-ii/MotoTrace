//  TrackingAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface

final class TrackingAnalyzer: TrackingAnalyzerInterface {
    private var thresholds: TrackingThresholds
    private var speedAnalyzer: SpeedAnalyzer
    private var leanAnalyzer: LeanAnalyzer
    private var recentLocation: LocationSnapshot?
    
    init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
        self.speedAnalyzer = SpeedAnalyzer(thresholds: thresholds)
        self.leanAnalyzer = LeanAnalyzer(thresholds: thresholds)
    }
    
    // MARK: - Location Tracking
    
    func updateLocation(_ data: LocationSnapshot) {
        recentLocation = data
    }
    
    // MARK: - Analysis (결과 반환만, 저장 X)
    
    func updateSpeed(_ data: LocationSnapshot) -> SpeedAnalyzerResult {
        speedAnalyzer.updateSpeed(data)
    }
    
    func updateAttitude(_ data: MotionSnapshot) -> LeanAnalyzerResult {
        guard let recentLocation else {
            return LeanAnalyzerResult()
        }
        return leanAnalyzer.updateAttitude(data, locationSnapshot: recentLocation)
    }
    
    func updateAcceleration(_ data: MotionSnapshot) {
        speedAnalyzer.updateAcceleration(data)
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
