//  TourIntent.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/21.
//

import Foundation

/// 라이딩 Feature의 Intent (MVI 패턴)
public enum TourIntent {
    case startTracking(tourName: String)
    case pauseTracking
    case resumeTracking
    case stopTracking
}
