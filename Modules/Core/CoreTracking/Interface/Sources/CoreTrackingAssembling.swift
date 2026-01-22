//
//  CoreTrackingAssembling.swift
//  CoreTrackingInterface
//
//  Created by 웅 on 1/22/26.
//

import Foundation

public struct CoreTrackingDependencies {
    public let thresholds: TrackingThresholds
    
    public init(thresholds: TrackingThresholds = TrackingPolicy.defaultThresholds) {
        self.thresholds = thresholds
    }
}

public protocol CoreTrackingAssembling {
    func assemble(dependencies: CoreTrackingDependencies) -> TrackingAnalyzerInterface
}
