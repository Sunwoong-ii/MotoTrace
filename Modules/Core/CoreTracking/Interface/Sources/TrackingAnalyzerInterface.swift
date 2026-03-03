//  TrackingAnalyzerInterface.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreLocation

public protocol TrackingAnalyzerInterface {
    func startTour(tourId: UUID)
    func finishTour() async throws
    
    func updateSpeed(_ data: LocationSnapshot) async throws -> TrackingEvent?
    func updateAttitude(_ data: MotionSnapshot) async throws -> TrackingEvent?
    func updateAcceleration(_ data: MotionSnapshot)
    
    func recordLocation(_ data: LocationSnapshot) async throws
    
    func stats() -> TourStats
    func setThresholds(_ thresholds: TrackingThresholds)
    func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double)
    func reset()
    
    // MARK: - Real-time Data Getters
    func currentSpeed() -> Double
    func currentLeanAngle() -> Double
    func topSpeed() -> Double
    func topLeanAngle() -> Double
}
