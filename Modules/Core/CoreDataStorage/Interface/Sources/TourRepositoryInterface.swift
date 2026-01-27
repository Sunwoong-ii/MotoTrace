//
//  TourRepositoryInterface.swift
//  CoreDataStorageInterface
//
//  Created by Woong on 2026/01/23.
//

import Foundation

/// 투어 Repository 프로토콜
public protocol TourRepositoryInterface {
    /// 투어 기록 저장 (통째로 저장할 때 사용)
    func saveTour(_ tour: TourRecordDTO) async throws
    
    /// 새로운 투어 시작 (기록 생성)
    func createTour(_ tour: TourRecordDTO) async throws
    
    /// 실시간 위치 추가 (내부 버퍼링 등을 통해 저장)
    func addLocation(_ location: LocationPointDTO, to tourId: UUID) async throws
    
    /// 이벤트 추가 (즉시 저장). 이벤트 시작 시 호출.
    func addEvent(_ event: TourEventDTO, to tourId: UUID) async throws
    
    /// 이벤트 업데이트 (종료 시점 갱신 등). 즉시 저장.
    func updateEvent(_ event: TourEventDTO) async throws
    
    /// 투어 종료 (버퍼 비우기 및 최종 저장)
    func finishTour(id: UUID) async throws
    
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
    public let duration: TimeInterval
    public let distance: Double
    public let avgSpeed: Double
    public let topSpeed: Double
    public let maxLeanAngle: Double
    public let tourName: String
    public let createdAt: Date
    public let locations: [LocationPointDTO]
    public let events: [TourEventDTO]
    
    public init(
        id: UUID = UUID(),
        duration: TimeInterval = .zero,
        distance: Double = 0,
        avgSpeed: Double = 0,
        topSpeed: Double = 0,
        maxLeanAngle: Double = 0,
        tourName: String,
        createdAt: Date = Date(),
        locations: [LocationPointDTO] = [],
        events: [TourEventDTO] = []
    ) {
        self.id = id
        self.duration = duration
        self.distance = distance
        self.avgSpeed = avgSpeed
        self.topSpeed = topSpeed
        self.maxLeanAngle = maxLeanAngle
        self.tourName = tourName
        self.createdAt = createdAt
        self.locations = locations
        self.events = events
    }
}

/// 투어 이벤트 DTO
public struct TourEventDTO: Identifiable, Codable {
    public let id: UUID
    public let type: String // RawValue of TourEventType
    public let startTime: Date
    public let endTime: Date?
    public let startSpeed: Double
    public let endSpeed: Double?
    public let latitude: Double
    public let longitude: Double
    
    public init(
        id: UUID = UUID(),
        type: String,
        startTime: Date,
        endTime: Date? = nil,
        startSpeed: Double,
        endSpeed: Double? = nil,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.startSpeed = startSpeed
        self.endSpeed = endSpeed
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// 위치 정보 DTO
public struct LocationPointDTO: Identifiable, Codable {
    public let id: UUID
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    public let speed: Double
    
    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        speed: Double
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.speed = speed
    }
}
