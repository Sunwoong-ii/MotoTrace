//
//  TourEvent.swift
//  CoreDataStorage
//
//  Created by Woong on 2026/01/23.
//

import Foundation
import SwiftData

/// 투어 이벤트 타입
public enum TourEventType: String, Codable {
    case rapidAcceleration
    case rapidDeceleration
    case leanAngle
}

/// 투어 이벤트 (급가속, 급감속, 린각)
@Model
public final class TourEvent {
    @Attribute(.unique) public var id: UUID
    public var typeRawValue: String
    public var timestamp: Date
    public var value: Double
    public var latitude: Double?
    public var longitude: Double?
    
    public var tourRecord: TourRecord?
    
    public var type: TourEventType {
        get { TourEventType(rawValue: typeRawValue) ?? .rapidAcceleration }
        set { typeRawValue = newValue.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        type: TourEventType,
        timestamp: Date,
        value: Double,
        latitude: Double? = nil,
        longitude: Double? = nil,
        tourRecord: TourRecord? = nil
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.timestamp = timestamp
        self.value = value
        self.latitude = latitude
        self.longitude = longitude
        self.tourRecord = tourRecord
    }
}
