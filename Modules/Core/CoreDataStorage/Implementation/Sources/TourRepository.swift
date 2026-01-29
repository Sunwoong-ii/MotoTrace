//
//  TourRepository.swift
//  CoreDataStorage
//
//  Created by Woong on 2026/01/23.
//

import Foundation
import SwiftData
import CoreDataStorageInterface

/// 투어 Repository 구현
@ModelActor
public actor TourRepository: TourRepositoryInterface {
    // MARK: - internal Properties
    /// 위치 정보 버퍼 (50개씩 모아서 저장 - 약 10초 분량)
    private var locationBuffer: [LocationPoint] = []
    private let locationBufferLimit = 50
    
    /// 투어스탯 30번 업데이트마다 저장
    private var statUpdateCount = 0
    private let statsSaveInterval = 30
    private var latestTripStats: TripStats?
    
    // MARK: - Real-time Tracking Methods
    
    public func createTour(_ dto: TourRecordDTO) async throws {
        let record = TourRecord(
            id: dto.id,
            duration: dto.duration,
            distance: dto.distance,
            avgSpeed: dto.avgSpeed,
            topSpeed: dto.topSpeed,
            maxLeanAngle: dto.maxLeanAngle,
            tourName: dto.tourName,
            createdAt: dto.createdAt
        )
        
        modelContext.insert(record)
        try modelContext.save()
    }
    
    public func addLocation(_ locationDto: LocationPointDTO, to tourId: UUID) async throws {
        let location = LocationPoint(
            id: locationDto.id,
            latitude: locationDto.latitude,
            longitude: locationDto.longitude,
            timestamp: locationDto.timestamp,
            speed: locationDto.speed
        )
        
        locationBuffer.append(location)
        
        if locationBuffer.count >= locationBufferLimit {
            try await flushLocationBuffer(to: tourId)
        }
    }
    
    public func addEvent(_ eventDto: TourEventDTO, to tourId: UUID) async throws {
        guard let tour = try fetchTourEntity(id: tourId) else { return }
        
        let event = TourEvent(
            id: eventDto.id,
            type: TourEventType(rawValue: eventDto.type) ?? .leanAngle,
            startTime: eventDto.startTime,
            startSpeed: eventDto.startSpeed,
            latitude: eventDto.latitude,
            longitude: eventDto.longitude,
            endTime: eventDto.endTime,
            endSpeed: eventDto.endSpeed,
            leanAngle: eventDto.leanAngle
        )
        
        // 관계 설정 & 즉시 저장
        event.record = tour
        tour.events.append(event)
        
        try modelContext.save()
    }
    
    public func finishTour(id: UUID) async throws {
        if !locationBuffer.isEmpty {
            try await flushLocationBuffer(to: id)
        }
        
        if let latestTripStats {
            try await updateTripStats(id: id, tripStats: latestTripStats)
        }
        
        statUpdateCount = 0
        latestTripStats = nil
    }
    
    // 주행 통계 (시간, 거리)
    public func updateTripStats(
        id: UUID,
        tripStats: TripStats
    ) async throws {
        latestTripStats = tripStats
        statUpdateCount += 1
        
        guard statUpdateCount > statsSaveInterval,
              let tour = try fetchTourEntity(id: id) else { return }
        
        tour.duration = tripStats.duration
        tour.distance = tripStats.distance
        tour.avgSpeed = tripStats.avgSpeed
        
        statUpdateCount = 0
        
        try modelContext.save()
    }
    
    // 성능 기록 (최고 속도, 최대 뱅킹각)
    public func updateTopSpeed(id: UUID, speed: Double) async throws {
        guard let tour = try fetchTourEntity(id: id) else { return }
        tour.topSpeed = speed
        try modelContext.save()
    }
    
    public func updateTopLeanAngle(id: UUID, leanAngle: Double) async throws {
        guard let tour = try fetchTourEntity(id: id) else { return }
        tour.maxLeanAngle = leanAngle
        try modelContext.save()
    }
    
    // MARK: - Private Helpers
    
    private func flushLocationBuffer(to tourId: UUID) async throws {
        guard let tour = try fetchTourEntity(id: tourId) else {
            locationBuffer.removeAll()
            return
        }

        tour.locations += locationBuffer
        
        locationBuffer.removeAll()
        try modelContext.save()
    }
    
    private func fetchTourEntity(id: UUID) throws -> TourRecord? {
        let descriptor = FetchDescriptor<TourRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - CRUD Methods
    
    public func saveTour(_ dto: TourRecordDTO) async throws {
        // 통째로 저장 (기존 로직 유지)
        let record = TourRecord(
            id: dto.id,
            duration: dto.duration,
            distance: dto.distance,
            avgSpeed: dto.avgSpeed,
            topSpeed: dto.topSpeed,
            maxLeanAngle: dto.maxLeanAngle,
            tourName: dto.tourName,
            createdAt: dto.createdAt
        )
        
        // Locations
        let locations = dto.locations.map { p in
            LocationPoint(
                latitude: p.latitude,
                longitude: p.longitude,
                timestamp: p.timestamp,
                speed: p.speed
            )
        }
        record.locations = locations
        
        // Events
        let events = dto.events.map { e in
            TourEvent(
                type: TourEventType(rawValue: e.type) ?? .leanAngle,
                startTime: e.startTime,
                startSpeed: e.startSpeed,
                latitude: e.latitude,
                longitude: e.longitude,
                endTime: e.endTime,
                endSpeed: e.endSpeed,
                leanAngle: e.leanAngle
            )
        }
        record.events = events
        
        modelContext.insert(record)
        try modelContext.save()
    }
    
    public func fetchAllTours() async throws -> [TourRecordDTO] {
        let descriptor = FetchDescriptor<TourRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)
        return records.map { convertToDTO($0) }
    }
    
    public func fetchTour(id: UUID) async throws -> TourRecordDTO? {
        let descriptor = FetchDescriptor<TourRecord>()
        let records = try modelContext.fetch(descriptor)
        
        return records.first.map { convertToDTO($0) }
    }
    
    public func deleteTour(id: UUID) async throws {
        let descriptor = FetchDescriptor<TourRecord>()
        let records = try modelContext.fetch(descriptor)

        if let record = records.first {
             modelContext.delete(record)
             try modelContext.save()
        }
    }
    
    private func convertToDTO(_ record: TourRecord) -> TourRecordDTO {
        let locationDTOs = record.locations.map { p in
            LocationPointDTO(
                latitude: p.latitude,
                longitude: p.longitude,
                timestamp: p.timestamp,
                speed: p.speed
            )
        }
        
        let eventDTOs = record.events.map { e in
            TourEventDTO(
                type: e.type.rawValue,
                startTime: e.startTime,
                endTime: e.endTime,
                startSpeed: e.startSpeed,
                endSpeed: e.endSpeed,
                latitude: e.latitude,
                longitude: e.longitude,
                leanAngle: e.leanAngle
            )
        }
        
        return TourRecordDTO(
            id: UUID(), // Entity에 ID가 없어서 임시 생성
            duration: record.duration,
            distance: record.distance,
            avgSpeed: record.avgSpeed,
            topSpeed: record.topSpeed,
            maxLeanAngle: record.maxLeanAngle,
            tourName: record.tourName,
            createdAt: record.createdAt,
            locations: locationDTOs,
            events: eventDTOs
        )
    }
}
