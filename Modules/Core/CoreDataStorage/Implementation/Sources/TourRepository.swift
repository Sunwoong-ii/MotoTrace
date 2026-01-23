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
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let modelContext = modelContainer.mainContext
        modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    }
    
    public func saveTour(_ tour: TourRecordDTO) async throws {
        let record = TourRecord(
            id: tour.id,
            startDate: tour.startDate,
            endDate: tour.endDate,
            totalDistanceKm: tour.totalDistanceKm,
            totalTimeSeconds: tour.totalTimeSeconds,
            averageSpeedKmh: tour.averageSpeedKmh
        )
        
        // RoutePoints 생성
        let routePoints = tour.routePoints.map { dto in
            RoutePoint(
                id: dto.id,
                latitude: dto.latitude,
                longitude: dto.longitude,
                timestamp: dto.timestamp,
                tourRecord: record
            )
        }
        record.routePoints = routePoints
        
        // Events 생성
        let events = tour.events.map { dto in
            TourEvent(
                id: dto.id,
                type: TourEventType(rawValue: dto.type) ?? .rapidAcceleration,
                timestamp: dto.timestamp,
                value: dto.value,
                latitude: dto.latitude,
                longitude: dto.longitude,
                tourRecord: record
            )
        }
        record.events = events
        
        modelContext.insert(record)
        try modelContext.save()
    }
    
    public func fetchAllTours() async throws -> [TourRecordDTO] {
        let descriptor = FetchDescriptor<TourRecord>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)
        return records.map { record in
            convertToDTO(record)
        }
    }
    
    public func fetchTour(id: UUID) async throws -> TourRecordDTO? {
        let descriptor = FetchDescriptor<TourRecord>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return convertToDTO(record)
    }
    
    public func deleteTour(id: UUID) async throws {
        let descriptor = FetchDescriptor<TourRecord>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else {
            return
        }
        modelContext.delete(record)
        try modelContext.save()
    }
    
    public func updateTour(_ tour: TourRecordDTO) async throws {
        let descriptor = FetchDescriptor<TourRecord>(
            predicate: #Predicate { $0.id == tour.id }
        )
        guard let record = try modelContext.fetch(descriptor).first else {
            throw NSError(domain: "TourRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Tour not found"])
        }
        
        record.endDate = tour.endDate
        record.totalDistanceKm = tour.totalDistanceKm
        record.totalTimeSeconds = tour.totalTimeSeconds
        record.averageSpeedKmh = tour.averageSpeedKmh
        
        try modelContext.save()
    }
    
    private func convertToDTO(_ record: TourRecord) -> TourRecordDTO {
        let routePoints = record.routePoints.map { point in
            RoutePointDTO(
                id: point.id,
                latitude: point.latitude,
                longitude: point.longitude,
                timestamp: point.timestamp
            )
        }
        
        let events = record.events.map { event in
            TourEventDTO(
                id: event.id,
                type: event.typeRawValue,
                timestamp: event.timestamp,
                value: event.value,
                latitude: event.latitude,
                longitude: event.longitude
            )
        }
        
        return TourRecordDTO(
            id: record.id,
            startDate: record.startDate,
            endDate: record.endDate,
            totalDistanceKm: record.totalDistanceKm,
            totalTimeSeconds: record.totalTimeSeconds,
            averageSpeedKmh: record.averageSpeedKmh,
            routePoints: routePoints,
            events: events
        )
    }
}
