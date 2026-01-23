//
//  TourRecord.swift
//  CoreDataStorage
//
//  Created by Woong on 2026/01/23.
//

import Foundation
import SwiftData

/// 투어 기록
@Model
public final class TourRecord {
    @Attribute(.unique) public var id: UUID
    public var startDate: Date
    public var endDate: Date?
    public var totalDistanceKm: Double
    public var totalTimeSeconds: TimeInterval
    public var averageSpeedKmh: Double
    
    @Relationship(deleteRule: .cascade, inverse: \RoutePoint.tourRecord)
    public var routePoints: [RoutePoint]
    
    @Relationship(deleteRule: .cascade, inverse: \TourEvent.tourRecord)
    public var events: [TourEvent]
    
    public init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        totalDistanceKm: Double = 0,
        totalTimeSeconds: TimeInterval = 0,
        averageSpeedKmh: Double = 0,
        routePoints: [RoutePoint] = [],
        events: [TourEvent] = []
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
