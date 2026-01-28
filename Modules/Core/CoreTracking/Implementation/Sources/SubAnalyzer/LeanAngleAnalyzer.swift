//  LeanAngleAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreTrackingInterface

final class LeanAnalyzer {
    private var thresholds: TrackingThresholds
    private var leanZeroRoll: Double = 0
    private var leanZeroPitch: Double = 0
    
    private var topLeanAngleDegrees: Double = 0
    var onEvent: ((LeanEvent) -> Void)?
    
    init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    func updateAttitude(_ data: MotionSnapshot, locationSnapshot: LocationSnapshot) -> LeanAngle {
        let deltaRoll = data.rollDegrees - leanZeroRoll
        let deltaPitch = data.pitchDegrees - leanZeroPitch
        let lean = abs(deltaRoll) >= abs(deltaPitch) ? deltaRoll : deltaPitch
        
        if abs(lean) > abs(topLeanAngleDegrees) {
            topLeanAngleDegrees = lean
            onEvent?(.maxLeanAngleUpdated(lean))
        }
        
        if abs(lean) >= thresholds.minLeanAngleDegrees {
            let event = TrackingEvent(
                startSpeedKmh: locationSnapshot.speedKmh,
                location: locationSnapshot.location,
                leanAngle: lean
            )
            
            onEvent?(.leanAngle(event))
        }
        
        return .init(angleDegrees: lean, location: locationSnapshot.location)
    }

    func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double) {
        leanZeroRoll = rollDegrees
        leanZeroPitch = pitchDegrees
    }
    
    func setThresholds(_ thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    func reset() {
        leanZeroRoll = 0
        leanZeroPitch = 0
        topLeanAngleDegrees = 0
    }
    
    // MARK: - Getters

    func topLeanAngle() -> Double {
        topLeanAngleDegrees
    }
}
