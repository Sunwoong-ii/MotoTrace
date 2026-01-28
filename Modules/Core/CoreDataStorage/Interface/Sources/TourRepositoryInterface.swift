//
//  TourRepositoryInterface.swift
//  CoreDataStorageInterface
//
//  Created by Woong on 2026/01/23.
//

import Foundation

/// 투어 Repository 프로토콜
public protocol TourRepositoryInterface {
    // MARK: - CRUD Methods
    
    /// 투어 기록 저장
    func saveTour(_ tour: TourRecordDTO) async throws
    
    /// 모든 투어 기록 조회
    func fetchAllTours() async throws -> [TourRecordDTO]
    
    /// 특정 투어 기록 조회
    func fetchTour(id: UUID) async throws -> TourRecordDTO?
    
    /// 투어 기록 삭제
    func deleteTour(id: UUID) async throws
    
    /// 투어 기록 업데이트
    func updateTour(_ tour: TourRecordDTO) async throws
    
    // MARK: - Real-time Tracking Methods
    
    /// 새 투어 생성 (트래킹 시작 시)
    func createTour(_ dto: TourRecordDTO) async throws
    
    /// 위치 정보 추가 (실시간)
    func addLocation(_ location: LocationPointDTO, to tourId: UUID) async throws
    
    /// 이벤트 추가 (급가속, 급감속, 뱅킹각)
    func addEvent(_ event: TourEventDTO, to tourId: UUID) async throws
    
    /// 이벤트 업데이트 (종료 시간, 종료 속도 등)
    func updateEvent(_ event: TourEventDTO) async throws
    
    /// 투어 통계 업데이트 (주기적)
    func updateTourStats(
        id: UUID,
        duration: TimeInterval,
        distance: Double,
        avgSpeed: Double,
        topSpeed: Double,
        maxLeanAngle: Double
    ) async throws
    
    /// 투어 완료 (트래킹 종료 시)
    func finishTour(id: UUID) async throws
}
