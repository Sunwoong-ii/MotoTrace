//  TrackingAnalyzerInterface.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreLocation

public protocol TrackingAnalyzerInterface {
    func updateSpeed(_ data: SpeedData) -> [SpeedChangeEvent]
    func updateLeanAngle(_ data: LeanAngleData) -> [TrackingEvent]
    func updateAttitude(_ data: AttitudeData) -> [TrackingEvent]
    func updateAcceleration(_ data: AccelerationData)
    func mapEventsToLocations(_ events: [TrackingEvent]) -> [TrackingEventLocation]
    func mapSpeedEventsToLocations(_ events: [SpeedChangeEvent]) -> [SpeedChangeEventLocation]
    func recordLocation(_ data: TrackingData)
    func route() -> [TrackingData]
    func stats() -> TourStats
    func setThresholds(_ thresholds: TrackingThresholds)
    func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double)
    func reset()
}
