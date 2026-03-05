import Foundation
import CoreLocation

public struct HistoryDetailState {
    public var tourName: String
    public var createdAt: Date
    public var duration: TimeInterval
    public var distance: Double
    public var avgSpeed: Double
    public var topSpeed: Double
    public var maxLeanAngle: Double
    public var routeCoordinates: [CLLocationCoordinate2D]
    
    public init(
        tourName: String = "",
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        distance: Double = 0,
        avgSpeed: Double = 0,
        topSpeed: Double = 0,
        maxLeanAngle: Double = 0,
        routeCoordinates: [CLLocationCoordinate2D] = []
    ) {
        self.tourName = tourName
        self.createdAt = createdAt
        self.duration = duration
        self.distance = distance
        self.avgSpeed = avgSpeed
        self.topSpeed = topSpeed
        self.maxLeanAngle = maxLeanAngle
        self.routeCoordinates = routeCoordinates
    }
}
