//  LeanAngleAnalyzer.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//
import Foundation
import CoreTrackingInterface

internal final class LeanAnalyzer {
    private var thresholds: TrackingThresholds
    private var leanZeroRoll: Double = 0
    private var leanZeroPitch: Double = 0
    
    internal init(thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    internal func updateLeanAngle(_ data: LeanAngleData) -> [TrackingEvent] {
        let relativeAngle = data.angleDegrees
        if abs(relativeAngle) >= thresholds.minLeanAngleDegrees {
            return [
                TrackingEvent(
                    type: .leanAngle,
                    timestamp: data.timestamp,
                    value: relativeAngle
                )
            ]
        }
        return []
    }
    
    internal func updateAttitude(_ data: AttitudeData) -> [TrackingEvent] {
        let deltaRoll = data.rollDegrees - leanZeroRoll
        let deltaPitch = data.pitchDegrees - leanZeroPitch
        let lean = abs(deltaRoll) >= abs(deltaPitch) ? deltaRoll : deltaPitch
        return updateLeanAngle(
            LeanAngleData(timestamp: data.timestamp, angleDegrees: lean)
        )
    }
    
    internal func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double) {
        leanZeroRoll = rollDegrees
        leanZeroPitch = pitchDegrees
    }
    
    internal func setThresholds(_ thresholds: TrackingThresholds) {
        self.thresholds = thresholds
    }
    
    internal func reset() {
        leanZeroRoll = 0
        leanZeroPitch = 0
    }
}
