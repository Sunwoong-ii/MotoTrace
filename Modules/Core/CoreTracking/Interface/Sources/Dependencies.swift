//
//  Dependencies.swift
//  CoreTrackingInterface
//
//  Created by 웅 on 1/23/26.
//

import Foundation

public struct CoreTrackingDependencies {
    public let thresholds: TrackingThresholds
    
    public init(thresholds: TrackingThresholds = TrackingPolicy.defaultThresholds) {
        self.thresholds = thresholds
    }
}
