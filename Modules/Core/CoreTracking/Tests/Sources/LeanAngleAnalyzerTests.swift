import XCTest
import CoreTrackingInterface
@testable import CoreTracking

/// LeanAnalyzer 단위 테스트
/// 좌표계 (CMDeviceMotion xTrueNorthZVertical 기준):
///   - device frame: x=오른쪽, y=위(화면 방향), z=화면 바깥(사용자 방향)
///   - world frame (NWU): x=진북, y=서, z=위
///   - GPS heading: 0=북, 시계방향(도)
///   - 기준 자세: 핸드폰 가로 눕힘(gz=-1), identity quaternion → 북쪽 주행 시 전진축 = device x
final class LeanAngleAnalyzerTests: XCTestCase {

    var sut: LeanAnalyzer!
    var thresholds: TrackingThresholds!

    override func setUp() {
        super.setUp()
        thresholds = TrackingThresholds(
            accelerationKmhPerSec: 5.0,
            decelerationKmhPerSec: 10.0,
            minLeanAngleDegrees: 3.0,
            stopSpeedKmh: 3.0
        )
        sut = LeanAnalyzer(thresholds: thresholds)
    }

    override func tearDown() {
        sut = nil
        thresholds = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// MotionSnapshot 생성 헬퍼
    private func makeMotion(
        gx: Double, gy: Double, gz: Double,
        qw: Double = 1, qx: Double = 0, qy: Double = 0, qz: Double = 0,
        roll: Double = 0, pitch: Double = 0
    ) -> MotionSnapshot {
        MotionSnapshot(
            timestamp: Date(),
            rollDegrees: roll, pitchDegrees: pitch,
            userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0,
            gravityX: gx, gravityY: gy, gravityZ: gz,
            quaternionW: qw, quaternionX: qx, quaternionY: qy, quaternionZ: qz
        )
    }

    /// LocationSnapshot 생성 헬퍼
    private func makeLocation(course: Double, speedKmh: Double = 60) -> LocationSnapshot {
        LocationSnapshot(
            timestamp: Date(),
            speedKmh: speedKmh,
            location: Location(latitude: 37.0, longitude: 127.0, timestamp: Date()),
            course: course
        )
    }

    // MARK: - 1. 영점 캘리브레이션

    func test_updateAttitude_첫데이터_영점_캘리브레이션() {
        // Given: 핸드폰 가로 눕힘, identity 자세, 북쪽 주행
        let motion = makeMotion(gx: 0, gy: 0, gz: -1)
        let location = makeLocation(course: 0)

        // When
        _ = sut.updateAttitude(motion, locationSnapshot: location)

        // Then
        XCTAssertEqual(sut.currentLeanAngle(), 0.0, accuracy: 0.01,
                       "첫 데이터는 영점으로 캘리브레이션되어 린앵글이 0이어야 합니다")
    }

    // MARK: - 2. GPS heading 유실 시 캐시된 전진 축으로 계속 계산

    func test_updateAttitude_heading_유실시_캐시된_전진축으로_계산() {
        // Given: 캘리브레이션 + 유효한 course로 전진 축 캐시 확보
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))

        // When: 정지 등으로 course = -1이 된 상태에서 30° 우측 기울기
        let half = (30.0 * .pi / 180.0) / 2.0
        _ = sut.updateAttitude(
            makeMotion(gx: 0,
                       gy: -sin(30.0 * .pi / 180.0),
                       gz: -cos(30.0 * .pi / 180.0),
                       qw: cos(half), qx: sin(half)),
            locationSnapshot: makeLocation(course: -1, speedKmh: 0)
        )

        // Then: 캐시된 전진 축으로 린앵글이 계속 계산되어야 함
        XCTAssertEqual(abs(sut.currentLeanAngle()), 30.0, accuracy: 1.0,
                       "course가 유실돼도 캐시된 전진 축으로 린앵글이 갱신되어야 합니다")
    }

    // MARK: - 2-1. course가 한 번도 없으면 오일러 델타 폴백

    func test_updateAttitude_course가_한번도_없으면_roll_델타_폴백() {
        // Given: course 없이 캘리브레이션 (실내 테스트/주행 시작 전 상황)
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1, roll: 5, pitch: 2),
                               locationSnapshot: makeLocation(course: -1, speedKmh: 0))

        // When: 폰을 25° 기울임 (roll 5→30, pitch 2→12)
        let result = sut.updateAttitude(
            makeMotion(gx: 0, gy: -0.42, gz: -0.9, roll: 30, pitch: 12),
            locationSnapshot: makeLocation(course: -1, speedKmh: 0)
        )

        // Then: 캘리브레이션 대비 roll/pitch 델타가 반영되어야 함
        XCTAssertEqual(sut.currentLeanAngle(), 25.0, accuracy: 0.01,
                       "course가 한 번도 없으면 roll 델타로 린앵글을 계산해야 합니다")
        XCTAssertEqual(result.pitchAngle, 10.0, accuracy: 0.01,
                       "course가 한 번도 없으면 pitch 델타로 경사각을 계산해야 합니다")
    }

    // MARK: - 2-2. 정지 상태에서는 이벤트·최대 린앵글 미기록

    func test_updateAttitude_정지속도에서는_이벤트와_최대린앵글_기록_안함() {
        // Given: course 없이 캘리브레이션 (정지 상태에서 폰 조작 상황)
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1),
                               locationSnapshot: makeLocation(course: -1, speedKmh: 0))

        // When: 정지 상태(속도 0)에서 폰을 40° 기울임 (임계값 3° 초과)
        let result = sut.updateAttitude(
            makeMotion(gx: 0, gy: -0.64, gz: -0.77, roll: 40),
            locationSnapshot: makeLocation(course: -1, speedKmh: 0)
        )

        // Then: UI용 현재 앵글은 갱신되지만 이벤트·최대 린앵글은 기록되지 않아야 함
        XCTAssertEqual(sut.currentLeanAngle(), 40.0, accuracy: 0.01,
                       "정지 상태에서도 현재 린앵글은 UI용으로 갱신되어야 합니다")
        XCTAssertNil(result.event,
                     "정지 속도에서는 린앵글 이벤트가 기록되지 않아야 합니다")
        XCTAssertNil(result.maxLeanAngleUpdated,
                     "정지 속도에서는 최대 린앵글이 갱신되지 않아야 합니다")
        XCTAssertEqual(sut.topLeanAngle(), 0.0, accuracy: 0.01,
                       "정지 속도에서는 최대 린앵글이 0으로 유지되어야 합니다")
    }

    // MARK: - 3. 오른쪽 30도 기울기
    // 바이크가 전진축(북=world-x)을 중심으로 30° 기울어짐 (세계좌표 x축 회전)
    // - 새 중력 device frame: (0, -sin30°, -cos30°)
    // - 새 attitude quaternion: (cos15°, sin15°, 0, 0)

    func test_updateAttitude_오른쪽_30도_기울기() {
        // Given: 캘리브레이션
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1, qw: 1, qx: 0, qy: 0, qz: 0),
                               locationSnapshot: makeLocation(course: 0))

        // When: 30° 우측 기울기
        let half = (30.0 * .pi / 180.0) / 2.0
        _ = sut.updateAttitude(
            makeMotion(gx: 0,
                       gy: -sin(30.0 * .pi / 180.0),
                       gz: -cos(30.0 * .pi / 180.0),
                       qw: cos(half), qx: sin(half), qy: 0, qz: 0),
            locationSnapshot: makeLocation(course: 0)
        )

        // Then: 린앵글 크기 ≈ 30°
        XCTAssertEqual(abs(sut.currentLeanAngle()), 30.0, accuracy: 1.0,
                       "30도 기울기가 약 30도로 계산되어야 합니다")
    }

    // MARK: - 4. 오르막/내리막에서 린앵글 불변
    // 바이크가 15° 오르막 → 중력이 전진 축(북=device-x) 방향으로 이동
    // 전진 축 수직 평면 투영으로 이 성분이 제거되어 린앵글 = 0이어야 함
    // - 새 중력: (sin15°, 0, -cos15°)
    // - 새 attitude quaternion: 측면축(y=서) 중심 15° 회전 = (cos7.5°, 0, sin7.5°, 0)

    func test_updateAttitude_오르막_경사에서_린앵글_불변() {
        // Given: 캘리브레이션
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1, qw: 1, qx: 0, qy: 0, qz: 0),
                               locationSnapshot: makeLocation(course: 0))

        // When: 15° 오르막
        let slope = 15.0 * .pi / 180.0
        let half = slope / 2.0
        _ = sut.updateAttitude(
            makeMotion(gx: sin(slope),
                       gy: 0,
                       gz: -cos(slope),
                       qw: cos(half), qx: 0, qy: sin(half), qz: 0),
            locationSnapshot: makeLocation(course: 0)
        )

        // Then: 린앵글 ≈ 0° (오르막은 측면 기울기가 아님)
        XCTAssertEqual(sut.currentLeanAngle(), 0.0, accuracy: 1.0,
                       "오르막 경사에서 린앵글이 변하지 않아야 합니다")
    }

    // MARK: - 5. 일시정지 후 재보정

    func test_handlePause_후_재보정() {
        // Given: 캘리브레이션 및 기울기 측정
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1, qw: 1, qx: 0, qy: 0, qz: 0),
                               locationSnapshot: makeLocation(course: 0))
        let half = (30.0 * .pi / 180.0) / 2.0
        _ = sut.updateAttitude(
            makeMotion(gx: 0, gy: -0.5, gz: -0.866, qw: cos(half), qx: sin(half)),
            locationSnapshot: makeLocation(course: 0)
        )

        // When: 일시정지 → 린앵글 리셋
        sut.handlePause()

        // Then: 린앵글 0 초기화
        XCTAssertEqual(sut.currentLeanAngle(), 0.0, accuracy: 0.01,
                       "Pause 후 린앵글이 0으로 초기화되어야 합니다")

        // And: 다음 첫 데이터로 재보정 (새 거치 각도 기준점 설정)
        _ = sut.updateAttitude(makeMotion(gx: 0.1, gy: 0, gz: -0.995, qw: 1, qx: 0, qy: 0, qz: 0),
                               locationSnapshot: makeLocation(course: 0))
        XCTAssertEqual(sut.currentLeanAngle(), 0.0, accuracy: 0.01,
                       "Pause 이후 첫 데이터는 새 영점으로 재보정되어야 합니다")
    }

    // MARK: - 6. 좌우 부호 일관성

    func test_updateAttitude_좌우_부호_일관성() {
        // 오른쪽 기울기와 왼쪽 기울기의 부호가 반대여야 함
        let half = (30.0 * .pi / 180.0) / 2.0

        // 오른쪽 기울기 (전진축 x 중심 회전, 상단이 동쪽으로 기욺)
        sut.reset()
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1, qw: 1, qx: 0, qy: 0, qz: 0),
                               locationSnapshot: makeLocation(course: 0))
        _ = sut.updateAttitude(
            makeMotion(gx: 0, gy: -0.5, gz: -0.866, qw: cos(half), qx: sin(half)),
            locationSnapshot: makeLocation(course: 0)
        )
        let rightLean = sut.currentLeanAngle()

        // 왼쪽 기울기
        sut.reset()
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1, qw: 1, qx: 0, qy: 0, qz: 0),
                               locationSnapshot: makeLocation(course: 0))
        _ = sut.updateAttitude(
            makeMotion(gx: 0, gy: 0.5, gz: -0.866, qw: cos(half), qx: -sin(half)),
            locationSnapshot: makeLocation(course: 0)
        )
        let leftLean = sut.currentLeanAngle()

        XCTAssertNotEqual(rightLean, 0.0, accuracy: 1.0,
                          "기울기 입력이 0이 아닌 린앵글로 계산되어야 합니다")
        XCTAssertEqual(rightLean, -leftLean, accuracy: 0.1,
                       "오른쪽과 왼쪽 기울기는 크기는 같고 부호가 반대여야 합니다")
    }
}
