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

/// 투어 기록 DTO
public struct TourRecordDTO: Identifiable, Codable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date?
    public let totalDistanceKm: Double
    public let totalTimeSeconds: TimeInterval
    public let averageSpeedKmh: Double
    public let routePoints: [RoutePointDTO]
    public let events: [TourEventDTO]
    
    public init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        totalDistanceKm: Double = 0,
        totalTimeSeconds: TimeInterval = 0,
        averageSpeedKmh: Double = 0,
        routePoints: [RoutePointDTO] = [],
        events: [TourEventDTO] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.totalDistanceKm = totalDistanceKm
        self.totalTimeSeconds = totalTimeSeconds
        self.averageSpeedKmh = averageSpeedKmh
        self.routePoints = routePoints
        self.events = events
    }
}

/// 경로 좌표 DTO
public struct RoutePointDTO: Identifiable, Codable {
    public let id: UUID
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        timestamp: Date
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}

/// 이벤트 DTO
public struct TourEventDTO: Identifiable, Codable {
    public let id: UUID
    public let type: String
    public let timestamp: Date
    public let value: Double
    public let latitude: Double?
    public let longitude: Double?
    
    public init(
        id: UUID = UUID(),
        type: String,
        timestamp: Date,
        value: Double,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.value = value
        self.latitude = latitude
        self.longitude = longitude
    }
}
