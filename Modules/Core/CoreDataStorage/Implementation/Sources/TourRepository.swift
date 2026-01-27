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
    private let bufferLimit = 50
    
    /// 현재 진행 중인 이벤트 개수 (이것이 0보다 크면 실시간 저장 모드로 전환)
    private var activeEventCount = 0
    
    public init(modelContainer: ModelContainer) {
        let modelContext = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    }
    
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
        // 초기 생성 시에는 빈 상태로 시작
        modelContext.insert(record)
        try modelContext.save()
    }
    
    public func addLocation(_ locationDto: LocationPointDTO, to tourId: UUID) async throws {
        // 1. Entity 생성 (아직 Context에 안 넣음)
        let location = LocationPoint(
            id: locationDto.id,
            latitude: locationDto.latitude,
            longitude: locationDto.longitude,
            timestamp: locationDto.timestamp,
            speed: locationDto.speed
        )
        
        // 2. 버퍼에 추가
        locationBuffer.append(location)
        
        // 3. 저장 조건 체크
        // - 버퍼가 꽉 찼거나 (50개)
        // - 현재 활성화된 중요 이벤트가 있거나 (activeEventCount > 0)
        if locationBuffer.count >= bufferLimit || activeEventCount > 0 {
            try await flushLocationBuffer(to: tourId)
        }
    }
    
    public func addEvent(_ eventDto: TourEventDTO, to tourId: UUID) async throws {
        // 1. 투어 찾기
        guard let tour = try fetchTourEntity(id: tourId) else { return }
        
        // 2. 이벤트 Entity 생성
        let event = TourEvent(
            id: eventDto.id,
            type: TourEventType(rawValue: eventDto.type) ?? .leanAngle,
            startTime: eventDto.startTime,
            startSpeed: eventDto.startSpeed,
            latitude: eventDto.latitude,
            longitude: eventDto.longitude,
            endTime: eventDto.endTime,
            endSpeed: eventDto.endSpeed
        )
        
        // 3. 관계 설정 & 즉시 저장
        event.record = tour
        tour.events.append(event)
        
        // 4. 활성화된 이벤트 카운트 증가 (종료 시간이 없는 경우)
        if eventDto.endTime == nil {
            activeEventCount += 1
        }
        
        // 5. 이벤트 발생 시점에는 버퍼 잔여 데이터도 같이 즉시 저장
        if !locationBuffer.isEmpty {
            try await flushLocationBuffer(to: tourId)
        } else {
            try modelContext.save()
        }
    }
    
    public func updateEvent(_ eventDto: TourEventDTO) async throws {
        // 1. 이벤트 Entity 찾기
        let descriptor = FetchDescriptor<TourEvent>(
            predicate: #Predicate { $0.id == eventDto.id }
        )
        guard let event = try modelContext.fetch(descriptor).first else { return }
        
        // 2. 정보 업데이트
        event.endTime = eventDto.endTime
        event.endSpeed = eventDto.endSpeed
        
        // 3. 활성화된 이벤트 카운트 감소 (종료 시간이 설정된 경우)
        if eventDto.endTime != nil {
            activeEventCount = max(0, activeEventCount - 1)
        }
        
        // 4. 즉시 저장 (및 버퍼 플러시)
        // 이벤트 종료 시점까지의 데이터도 중요하므로 버퍼 비움
        if let tourId = event.record?.id, !locationBuffer.isEmpty {
             try await flushLocationBuffer(to: tourId)
        } else {
             try modelContext.save()
        }
    }
    
    public func finishTour(id: UUID) async throws {
        // 남은 버퍼 모두 저장
        if !locationBuffer.isEmpty {
            try await flushLocationBuffer(to: id)
        }
        activeEventCount = 0 // 초기화
        try modelContext.save()
    }
    
    // MARK: - Private Helpers
    
    private func flushLocationBuffer(to tourId: UUID) async throws {
        guard let tour = try fetchTourEntity(id: tourId) else {
            // 투어가 없으면 버퍼만 비우고 리턴
            locationBuffer.removeAll()
            return
        }
        
        // 관계 설정
        for location in locationBuffer {
            tour.locations.append(location)
        }
        
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
        
        let locations = dto.locations.map { p in
            LocationPoint(
                id: p.id,
                latitude: p.latitude,
                longitude: p.longitude,
                timestamp: p.timestamp,
                speed: p.speed
            )
        }
        record.locations = locations
        
        let events = dto.events.map { e in
            TourEvent(
                id: e.id,
                type: TourEventType(rawValue: e.type) ?? .leanAngle,
                startTime: e.startTime,
                startSpeed: e.startSpeed,
                latitude: e.latitude,
                longitude: e.longitude,
                endTime: e.endTime,
                endSpeed: e.endSpeed
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
        guard let record = try fetchTourEntity(id: id) else { return nil }
        return convertToDTO(record)
    }
    
    public func deleteTour(id: UUID) async throws {
        if let record = try fetchTourEntity(id: id) {
            modelContext.delete(record)
            try modelContext.save()
        }
    }
    
    public func updateTour(_ dto: TourRecordDTO) async throws {
        guard let record = try fetchTourEntity(id: dto.id) else {
            throw NSError(domain: "TourRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Tour not found"])
        }
        
        // 필요한 필드 업데이트
        record.duration = dto.duration
        record.distance = dto.distance
        record.avgSpeed = dto.avgSpeed
        record.topSpeed = dto.topSpeed
        record.maxLeanAngle = dto.maxLeanAngle
        // ... 기타 필드 업데이트
        
        try modelContext.save()
    }
    
    private func convertToDTO(_ record: TourRecord) -> TourRecordDTO {
        // 좌표가 너무 많으면 목록 조회 시에는 제외하는 게 성능상 좋을 수 있음.
        // 하지만 요구사항에 따라 포함.
        let locationDTOs = record.locations.sorted(by: { $0.timestamp < $1.timestamp }).map { p in
            LocationPointDTO(
                id: p.id,
                latitude: p.latitude,
                longitude: p.longitude,
                timestamp: p.timestamp,
                speed: p.speed
            )
        }
        
        let eventDTOs = record.events.map { e in
            TourEventDTO(
                id: e.id,
                type: e.type.rawValue,
                startTime: e.startTime,
                endTime: e.endTime,
                startSpeed: e.startSpeed,
                endSpeed: e.endSpeed,
                latitude: e.latitude,
                longitude: e.longitude
            )
        }
        
        return TourRecordDTO(
            id: record.id,
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

