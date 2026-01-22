//
//  CoreTrackingAssembler.swift
//  CoreTrackingInterface
//
//  Created by 웅 on 1/22/26.
//

import Foundation
import CoreTrackingInterface

public enum CoreTrackingAssembler: CoreTrackingAssembling {
    public func assemble(dependencies: CoreTrackingDependencies) -> TrackingAnalyzerInterface {
        return TrackingAnalyzer(thresholds: dependencies.thresholds)
    }
}
