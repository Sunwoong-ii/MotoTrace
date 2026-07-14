//  TrackingAnalyzerInterface.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreLocation

public protocol TrackingAnalyzerInterface {
    /// 위치 갱신 (린앵글 계산 시 참조용)
    func updateLocation(_ data: LocationSnapshot)
    
    /// 속도 분석 — 결과를 반환만 하고 저장은 하지 않음
    func updateSpeed(_ data: LocationSnapshot) -> SpeedAnalyzerResult
    
    /// 자세 분석 — 결과를 반환만 하고 저장은 하지 않음
    func updateAttitude(_ data: MotionSnapshot) -> LeanAnalyzerResult
    
    /// 세션 복구 시 이전 누적 통계 시딩 — 앱 재시작으로 소실된 메모리 누적값을 DB 값으로 복원
    func restoreStats(
        movingTimeSeconds: TimeInterval,
        movingDistanceKm: Double,
        topSpeedKmh: Double,
        topLeanAngleDegrees: Double
    )

    func stats() -> TourStats
    func setThresholds(_ thresholds: TrackingThresholds)
    func calibrateLeanZero(rollDegrees: Double, pitchDegrees: Double)
    func reset()
    func handlePause()
    
    // MARK: - Real-time Data Getters
    func currentSpeed() -> Double
    func currentLeanAngle() -> Double
    func topSpeed() -> Double
    func topLeanAngle() -> Double
}
