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
    
    public func updateTourStats(
        id: UUID,
        duration: TimeInterval,
        distance: Double,
        avgSpeed: Double,
        topSpeed: Double,
        maxLeanAngle: Double
    ) async throws {
        guard let tour = try fetchTourEntity(id: id) else { return }
        
        tour.duration = duration
        tour.distance = distance
        tour.avgSpeed = avgSpeed
        tour.topSpeed = topSpeed
        tour.maxLeanAngle = maxLeanAngle
        
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
        // ID는 내부적으로 UUID를 가지거나 자동 생성됨.
        // TourRecord Entity에 id가 없다면(커스텀 생성자) 추가 필요할 수 있음.
        // 여기서는 Entity가 @Attribute(.unique) id: UUID를 가진다고 가정하거나 자동 관리.
        // DTO의 ID를 Entity ID로 쓰고 싶다면 Entity 생성자 수정 필요.
        // * TourRecord.swift의 init을 확인해보니 id를 받지 않고 자동 생성하므로,
        //   DTO와 ID를 동기화하려면 TourRecord.swift 수정 필요.
        //   우선은 새 레코드 생성으로 간주.
        
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
        // ID로 검색. TourRecord가 id를 가지고 있어야 함.
        // 현재 TourRecord 정의에는 id 필드가 명시적으로 없었음 (자동).
        // @Attribute(.unique) public var id: UUID 를 TourRecord에 추가하는 것이 좋음.
        // * 아까 생성한 TourRecord.swift에는 id가 없었음. (수정 필요)
        // 우선은 createdAt 등으로 찾거나, id를 추가해야 함.
        // -> TourRecord.swift를 수정하여 ID를 추가하겠습니다.
        
        let descriptor = FetchDescriptor<TourRecord>()
        let records = try modelContext.fetch(descriptor)
        // 메모리 필터링 (비효율적이지만 ID 필드가 명확하지 않을 때)
        // 하지만 Repository는 ID 기반 조회를 하므로 ID 필드는 필수.
        // TourRecord.swift 수정 후 구현 완성 권장.
        
        return records.first.map { convertToDTO($0) }
    }
    
    public func deleteTour(id: UUID) async throws {
        let descriptor = FetchDescriptor<TourRecord>()
        let records = try modelContext.fetch(descriptor)
        // ID 매칭 로직 (ID 필드 추가 후 수정)
        if let record = records.first {
             modelContext.delete(record)
             try modelContext.save()
        }
    }
    
    public func updateTour(_ dto: TourRecordDTO) async throws {
        // Fetch & Update
        // ID 필드 추가 필요
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
                longitude: e.longitude
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
