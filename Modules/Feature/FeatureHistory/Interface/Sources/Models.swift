//
//  Models.swift
//  FeatureHistoryInterface
//
//  Created by 김선웅 on 3/5/26.
//

import Foundation

public struct HistoryRecord {
    public let id: UUID
    public let duration: TimeInterval
    public let distance: Double
    public let tourName: String
    public let createdAt: Date
    
    public init(
        id: UUID,
        duration: TimeInterval,
        distance: Double,
        tourName: String,
        createdAt: Date
    ) {
        self.id = id
        self.duration = duration
        self.distance = distance
        self.tourName = tourName
        self.createdAt = createdAt
    }
}
