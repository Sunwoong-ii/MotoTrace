import XCTest
import CoreTrackingInterface
@testable import CoreTracking

final class LeanAngleAnalyzerTests: XCTestCase {
    var sut: LeanAnalyzer!
    var thresholds: TrackingThresholds!
    
    override func setUp() {
        super.setUp()
        thresholds = TrackingThresholds(
            accelerationKmhPerSec: 5.0,
            decelerationKmhPerSec: 10.0,
            minLeanAngleDegrees: 3.0,
            stopSpeedKmh: 60.0
        )
        sut = LeanAnalyzer(thresholds: thresholds)
    }
    
    override func tearDown() {
        sut = nil
        thresholds = nil
        super.tearDown()
    }
    
    func test_updateAttitude_첫데이터로_영점이_자동으로_잡히는지_검증() {
        // Given
        let initialMotion = MotionSnapshot(timestamp: Date(), rollDegrees: 10.0, pitchDegrees: 5.0, userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0)
        let dummyLocation = LocationSnapshot(timestamp: Date(), speedKmh: 0, location: Location(latitude: 0, longitude: 0, timestamp: Date()))
        
        // When
        let _ = sut.updateAttitude(initialMotion, locationSnapshot: dummyLocation)
        
        // Then
        XCTAssertEqual(sut.currentLeanAngle(), 0.0, "첫 데이터는 영점으로 세팅되어 뱅킹각이 0이어야 합니다.")
    }
    
    func test_updateAttitude_롤값_변화시_뱅킹각이_올바르게_계산되는지() {
        // Given
        let initialMotion = MotionSnapshot(timestamp: Date(), rollDegrees: 10.0, pitchDegrees: 0.0, userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0)
        let leanedMotion = MotionSnapshot(timestamp: Date(), rollDegrees: 25.0, pitchDegrees: 0.0, userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0)
        let dummyLocation = LocationSnapshot(timestamp: Date(), speedKmh: 0, location: Location(latitude: 0, longitude: 0, timestamp: Date()))
        
        // When
        _ = sut.updateAttitude(initialMotion, locationSnapshot: dummyLocation) // 영점: 10 -> 0
        _ = sut.updateAttitude(leanedMotion, locationSnapshot: dummyLocation)  // 눕힘: 25 - 10 = 15
        
        // Then
        XCTAssertEqual(sut.currentLeanAngle(), 15.0, "10도에서 25도로 변했으므로 뱅킹각은 15도여야 합니다.")
    }
    
    func test_handlePause를_호출하면_영점설정이_초기화되는지() {
        // Given
        let initialMotion = MotionSnapshot(timestamp: Date(), rollDegrees: 10.0, pitchDegrees: 0.0, userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0)
        let dummyLocation = LocationSnapshot(timestamp: Date(), speedKmh: 0, location: Location(latitude: 0, longitude: 0, timestamp: Date()))
        
        _ = sut.updateAttitude(initialMotion, locationSnapshot: dummyLocation) // 영점이 잡힘 (isCalibrated = true)
        
        // When
        sut.handlePause()
        
        // Then
        XCTAssertEqual(sut.currentLeanAngle(), 0.0, "Pause 후에는 현재 뱅킹각이 0으로 초기화되어야 합니다.")
        
        // 추가: 다시 새로운 데이터가 들어올 때 영점이 새롭게 잡히는지 검증
        let newInitialMotion = MotionSnapshot(timestamp: Date(), rollDegrees: -5.0, pitchDegrees: 0.0, userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0)
        _ = sut.updateAttitude(newInitialMotion, locationSnapshot: dummyLocation)
        XCTAssertEqual(sut.currentLeanAngle(), 0.0, "Pause 이후의 첫 데이터는 다시 영점으로 세팅되어야 합니다.")
    }
}
