//  TourIntent.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/21.
//

import Foundation

public enum TourIntent {
    case startTracking(tourName: String)
    case pauseTracking
    case resumeTracking
    case stopTracking
}
