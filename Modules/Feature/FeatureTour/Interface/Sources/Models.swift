//
//  Models.swift
//  FeatureTourInterface
//
//  Created by 김선웅 on 3/5/26.
//

import Foundation
import CoreTrackingInterface

public struct LiveStats {
    public let speed: String          // 현재 속도 (live)
    public let leanAngle: String      // 현재 뱅킹각 (live)
    public let location: Location     // 현재 위치
    public let distance: String       // 총 거리
    public let duration: String       // 총 시간
    public let avgSpeed: String       // 평균 속도
    public let inclination: String    // 현재 경사각 (°, 양수=오르막)
    
    public init(
        speed: String = "0",
        leanAngle: String = "0",
        location: Location = Location(latitude: 0, longitude: 0, timestamp: Date()),
        distance: String = "0.0",
        duration: String = "00:00:00",
        avgSpeed: String = "0",
        inclination: String = "0"
    ) {
        self.speed = speed
        self.leanAngle = leanAngle
        self.location = location
        self.distance = distance
        self.duration = duration
        self.avgSpeed = avgSpeed
        self.inclination = inclination
    }
}

public struct DisplayValue {
    public let value: String
    public let unit: String
    
    public init(value: String, unit: String) {
        self.value = value
        self.unit = unit
    }
}
