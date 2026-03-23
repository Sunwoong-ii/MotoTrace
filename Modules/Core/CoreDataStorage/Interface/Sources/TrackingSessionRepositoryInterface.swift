//
//  TrackingSessionRepositoryInterface.swift
//  CoreDataStorageInterface
//
//  Created by Woong on 2026/03/23.
//

import Foundation

// MARK: - Model

/// 앱이 강제 종료되더라도 복구할 수 있도록 UserDefaults에 저장하는 세션 메타데이터
public struct ActiveTrackingSession: Codable {
    public let tourId: UUID
    public let startDate: Date
    public let pausedAt: Date?
    /// "tracking" | "paused"
    public let statusRaw: String

    public init(
        tourId: UUID,
        startDate: Date,
        pausedAt: Date?,
        statusRaw: String
    ) {
        self.tourId = tourId
        self.startDate = startDate
        self.pausedAt = pausedAt
        self.statusRaw = statusRaw
    }
}

// MARK: - Interface

/// 트래킹 세션 메타데이터 영속화 담당
public protocol TrackingSessionRepositoryInterface: AnyObject {
    /// 현재 세션 저장 (startTracking / pauseTracking / resumeTracking 시 호출)
    func save(_ session: ActiveTrackingSession)
    /// 저장된 세션 복원 (앱 재실행 시 호출)
    func load() -> ActiveTrackingSession?
    /// 세션 삭제 (stopTracking 완료 시 호출)
    func clear()
}
