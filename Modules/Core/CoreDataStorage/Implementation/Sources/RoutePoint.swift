//
//  RoutePoint.swift
//  CoreDataStorage
//
//  Created by Woong on 2026/01/23.
//

import Foundation
import SwiftData

/// 투어 경로 좌표
@Model
public final class RoutePoint {
    @Attribute(.unique) public var id: UUID
    public var latitude: Double
    public var longitude: Double
    public var timestamp: Date
    
    public var tourRecord: TourRecord?
    
    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        tourRecord: TourRecord? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.tourRecord = tourRecord
    }
}
