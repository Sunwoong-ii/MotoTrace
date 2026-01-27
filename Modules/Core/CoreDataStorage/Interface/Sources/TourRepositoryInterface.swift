//
//  TourRepositoryInterface.swift
//  CoreDataStorageInterface
//
//  Created by Woong on 2026/01/23.
//

import Foundation

/// 투어 Repository 프로토콜
public protocol TourRepositoryInterface {
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
}
