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
    /// 앱 재실행 시 백그라운드 종료로 끊긴 세션 복구
    case restoreTracking
}
