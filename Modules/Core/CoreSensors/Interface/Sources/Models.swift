//  Models.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import Foundation
import CoreLocation

public struct Location: Codable {
    public let latitude: Double
    public let longitude: Double
    public let speedKmh: Double
    public let horizontalAccuracy: Double
    public let timestamp: Date
    /// GPS 진행 방향 (도, 0=북 시계방향). 유효하지 않으면 -1
    public let course: Double

    public init(
        latitude: Double,
        longitude: Double,
        speedKmh: Double,
        horizontalAccuracy: Double,
        timestamp: Date,
        course: Double = -1
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.speedKmh = speedKmh
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
        self.course = course
    }
}

public struct Motion: Codable {
    public let rollDegrees: Double
    public let pitchDegrees: Double
    public let yawDegrees: Double
    public let userAccelerationX: Double
    public let userAccelerationY: Double
    public let userAccelerationZ: Double
    public let timestamp: Date
    // 중력 벡터 (device frame, 크기 1) — 린앵글 계산용
    public let gravityX: Double
    public let gravityY: Double
    public let gravityZ: Double
    // Attitude 쿼터니언 (device→world 변환용)
    public let quaternionW: Double
    public let quaternionX: Double
    public let quaternionY: Double
    public let quaternionZ: Double

    public init(
        rollDegrees: Double,
        pitchDegrees: Double,
        yawDegrees: Double,
        userAccelerationX: Double,
        userAccelerationY: Double,
        userAccelerationZ: Double,
        timestamp: Date,
        gravityX: Double = 0,
        gravityY: Double = 0,
        gravityZ: Double = -1,
        quaternionW: Double = 1,
        quaternionX: Double = 0,
        quaternionY: Double = 0,
        quaternionZ: Double = 0
    ) {
        self.rollDegrees = rollDegrees
        self.pitchDegrees = pitchDegrees
        self.yawDegrees = yawDegrees
        self.userAccelerationX = userAccelerationX
        self.userAccelerationY = userAccelerationY
        self.userAccelerationZ = userAccelerationZ
        self.timestamp = timestamp
        self.gravityX = gravityX
        self.gravityY = gravityY
        self.gravityZ = gravityZ
        self.quaternionW = quaternionW
        self.quaternionX = quaternionX
        self.quaternionY = quaternionY
        self.quaternionZ = quaternionZ
    }
}
