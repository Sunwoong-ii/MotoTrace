//
//  CoreTrackingAssembly.swift
//  CoreTracking
//
//  Created by Woong on 2026/01/23.
//

import AppDI
import CoreTrackingInterface
import Foundation

public enum CoreTrackingAssembly: DIAssembly {
    public static func register(in container: AppDIContainer) {
        container.register(TrackingAnalyzerInterface.self, scope: .transient) { (deps: CoreTrackingDependencies) in
            return TrackingAnalyzer(thresholds: deps.thresholds)
        }
    }
}
