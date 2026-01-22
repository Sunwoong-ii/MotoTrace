//
//  TrackingPolicy.swift
//  CoreTrackingInterface
//
//  Created by Woong on 2026/01/22.
//

import Foundation

public enum TrackingPolicy {
    public static let defaultThresholds = TrackingThresholds(
        accelerationKmhPerSec: 16.7,
        decelerationKmhPerSec: 16.7,
        minLeanAngleDegrees: 30.0,
        stopSpeedKmh: 3.0
    )
}
