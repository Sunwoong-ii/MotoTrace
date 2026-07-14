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

    /// 우측 기울기 degrees°에 해당하는 gravity+quaternion 스냅샷 (전진축=북 기준, 0=직립)
    private func leanMotion(degrees: Double) -> MotionSnapshot {
        let rad = degrees * .pi / 180.0
        let half = rad / 2.0
        return makeMotion(gx: 0, gy: -sin(rad), gz: -cos(rad), qw: cos(half), qx: sin(half))
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

    // MARK: - 2-2. 정지 상태에서는 이벤트만 미기록, 최대 린앵글은 갱신

    func test_updateAttitude_정지속도에서는_이벤트_미기록_최대린앵글은_갱신() {
        // Given: course 없이 캘리브레이션 (정지 상태에서 폰 조작 상황)
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1),
                               locationSnapshot: makeLocation(course: -1, speedKmh: 0))

        // When: 정지 상태(속도 0)에서 폰을 40° 기울임 (임계값 3° 초과)
        let result = sut.updateAttitude(
            makeMotion(gx: 0, gy: -0.64, gz: -0.77, roll: 40),
            locationSnapshot: makeLocation(course: -1, speedKmh: 0)
        )

        // Then: 현재 앵글과 최대 린앵글은 갱신되고, 이벤트만 기록되지 않아야 함
        XCTAssertEqual(sut.currentLeanAngle(), 40.0, accuracy: 0.01,
                       "정지 상태에서도 현재 린앵글은 갱신되어야 합니다")
        XCTAssertEqual(sut.topLeanAngle(), 40.0, accuracy: 0.01,
                       "정지 상태에서도 최대 린앵글은 현재 앵글을 따라가야 합니다")
        XCTAssertEqual(result.maxLeanAngleUpdated ?? 0, 40.0, accuracy: 0.01,
                       "최대 린앵글 갱신이 결과에 포함되어야 합니다")
        XCTAssertNil(result.event,
                     "정지 속도에서는 린앵글 이벤트가 기록되지 않아야 합니다")
    }

    // MARK: - 2-3. 주행 속도에서는 코너 종료 시 이벤트 기록

    func test_updateAttitude_주행속도에서_코너종료시_이벤트_기록() {
        // Given: 캘리브레이션 + 유효한 course
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))

        // When: 주행 속도(60km/h)에서 30° 우측 기울기 (임계값 3° 초과) — 에피소드 시작
        let inCorner = sut.updateAttitude(
            leanMotion(degrees: 30),
            locationSnapshot: makeLocation(course: 0, speedKmh: 60)
        )

        // Then: 에피소드 진행 중에는 이벤트가 없고 최대 린앵글만 갱신
        XCTAssertNil(inCorner.event,
                     "코너 진행 중에는 이벤트가 방출되지 않아야 합니다")
        XCTAssertNotNil(inCorner.maxLeanAngleUpdated,
                        "주행 속도에서 최대 린앵글이 갱신되어야 합니다")

        // When: 임계값 아래로 복귀 (코너 종료)
        let cornerExit = sut.updateAttitude(
            leanMotion(degrees: 0),
            locationSnapshot: makeLocation(course: 0, speedKmh: 60)
        )

        // Then: 코너 종료 시점에 이벤트 1건 방출
        XCTAssertNotNil(cornerExit.event,
                        "코너 종료 시점에 이벤트가 방출되어야 합니다")
    }

    // MARK: - 2-4. 세션 복구 시딩 후 더 작은 기울기는 최대 린앵글 미갱신

    func test_restoreTopLeanAngle_시딩값보다_작은_기울기는_최대_린앵글_갱신_안함() {
        // Given: 이전 세션 최대 34.7°로 시딩 + 캘리브레이션
        sut.restoreTopLeanAngle(34.7)
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1),
                               locationSnapshot: makeLocation(course: 0))

        // When: 시딩값보다 작은 30° 기울기
        let half = (30.0 * .pi / 180.0) / 2.0
        let result = sut.updateAttitude(
            makeMotion(gx: 0,
                       gy: -sin(30.0 * .pi / 180.0),
                       gz: -cos(30.0 * .pi / 180.0),
                       qw: cos(half), qx: sin(half)),
            locationSnapshot: makeLocation(course: 0)
        )

        // Then: 최대 린앵글은 시딩값 유지 (복구 직후 더 낮은 값이 DB를 덮어쓰는 버그 방지)
        XCTAssertNil(result.maxLeanAngleUpdated,
                     "시딩된 최대 린앵글보다 작으면 갱신되지 않아야 합니다")
        XCTAssertEqual(sut.topLeanAngle(), 34.7, accuracy: 0.001,
                       "최대 린앵글은 시딩값을 유지해야 합니다")
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

    // MARK: - 7. 코너 에피소드 — 코너당 피크 이벤트 1건

    func test_코너에피소드_기울기변화하는_한코너는_피크값_이벤트_1건() {
        // Given: 캘리브레이션 후 한 코너 안에서 기울기가 10° → 38°(피크, 65km/h) → 20°로 변화
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))
        var events: [TrackingEvent] = []

        for (degrees, speed) in [(10.0, 60.0), (38.0, 65.0), (20.0, 55.0)] {
            let result = sut.updateAttitude(
                leanMotion(degrees: degrees),
                locationSnapshot: makeLocation(course: 0, speedKmh: speed)
            )
            if let event = result.event { events.append(event) }
        }

        // When: 임계값 아래로 복귀 (코너 종료)
        let exit = sut.updateAttitude(leanMotion(degrees: 0), locationSnapshot: makeLocation(course: 0))
        if let event = exit.event { events.append(event) }

        // Then: 이벤트는 1건, 값은 피크 시점의 각도·속도
        XCTAssertEqual(events.count, 1,
                       "한 코너에서는 이벤트가 1건만 방출되어야 합니다")
        XCTAssertEqual(abs(events.first?.leanAngle ?? 0), 38.0, accuracy: 1.0,
                       "이벤트는 피크 시점의 린앵글이어야 합니다")
        XCTAssertEqual(events.first?.startSpeedKmh ?? 0, 65.0, accuracy: 0.001,
                       "이벤트는 피크 시점의 속도여야 합니다")
    }

    func test_코너에피소드_임계값미만_유지시_이벤트_없음() {
        // Given: 캘리브레이션
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))

        // When: 임계값(3°) 미만 기울기만 반복
        let r1 = sut.updateAttitude(leanMotion(degrees: 1), locationSnapshot: makeLocation(course: 0))
        let r2 = sut.updateAttitude(leanMotion(degrees: 2), locationSnapshot: makeLocation(course: 0))
        let r3 = sut.updateAttitude(leanMotion(degrees: 0), locationSnapshot: makeLocation(course: 0))

        // Then
        XCTAssertNil(r1.event); XCTAssertNil(r2.event)
        XCTAssertNil(r3.event, "임계값을 넘은 적이 없으면 이벤트가 방출되지 않아야 합니다")
    }

    func test_코너에피소드_코너_두번이면_이벤트_2건() {
        // Given: 캘리브레이션
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))
        var events: [TrackingEvent] = []

        // When: 코너1(30°) → 직립 → 코너2(20°) → 직립
        for degrees in [30.0, 0.0, 20.0, 0.0] {
            let result = sut.updateAttitude(
                leanMotion(degrees: degrees),
                locationSnapshot: makeLocation(course: 0)
            )
            if let event = result.event { events.append(event) }
        }

        // Then: 코너마다 1건씩 총 2건
        XCTAssertEqual(events.count, 2,
                       "직립 구간으로 분리된 코너 두 개는 이벤트 2건이어야 합니다")
        XCTAssertEqual(abs(events[0].leanAngle ?? 0), 30.0, accuracy: 1.0)
        XCTAssertEqual(abs(events[1].leanAngle ?? 0), 20.0, accuracy: 1.0)
    }

    func test_코너에피소드_경계노이즈로_임계값_살짝_내려가도_한코너로_유지() {
        // Given: 캘리브레이션 후 코너 진입 (임계값 3°, 이탈 히스테리시스 하한 1.5°)
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))
        var events: [TrackingEvent] = []

        // When: 30° → 2°(임계값 아래지만 이탈 하한 위, 경계 노이즈) → 30° → 0°(진짜 종료)
        for degrees in [30.0, 2.0, 30.0, 0.0] {
            let result = sut.updateAttitude(
                leanMotion(degrees: degrees),
                locationSnapshot: makeLocation(course: 0)
            )
            if let event = result.event { events.append(event) }
        }

        // Then: 노이즈로 쪼개지지 않고 한 코너 이벤트 1건
        XCTAssertEqual(events.count, 1,
                       "임계값 언저리 노이즈로 한 코너가 여러 이벤트로 쪼개지면 안 됩니다")
        XCTAssertEqual(abs(events.first?.leanAngle ?? 0), 30.0, accuracy: 1.0)
    }

    func test_코너에피소드_정차로_속도이탈시_피크_방출() {
        // Given: 캘리브레이션 후 코너 진행 중 (30°, 60km/h)
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))
        let inCorner = sut.updateAttitude(leanMotion(degrees: 30),
                                          locationSnapshot: makeLocation(course: 0, speedKmh: 60))
        XCTAssertNil(inCorner.event)

        // When: 기울기 유지한 채 정차 속도(stopSpeedKmh 미만)로 떨어짐
        let stopped = sut.updateAttitude(leanMotion(degrees: 30),
                                         locationSnapshot: makeLocation(course: 0, speedKmh: 0))

        // Then: 에피소드가 종료돼 피크 이벤트가 방출되어야 함 (주행 종료 시 코너 유실 방지)
        XCTAssertNotNil(stopped.event,
                        "정차로 에피소드가 끝나면 피크 이벤트가 방출되어야 합니다")
        XCTAssertEqual(abs(stopped.event?.leanAngle ?? 0), 30.0, accuracy: 1.0)
    }

    func test_코너에피소드_일시정지시_진행중_에피소드_폐기() {
        // Given: 코너 진행 중 (아직 방출 전)
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))
        _ = sut.updateAttitude(leanMotion(degrees: 30),
                               locationSnapshot: makeLocation(course: 0, speedKmh: 60))

        // When: 일시정지 → 재보정 후 직립 주행
        sut.handlePause()
        _ = sut.updateAttitude(makeMotion(gx: 0, gy: 0, gz: -1), locationSnapshot: makeLocation(course: 0))
        let afterResume = sut.updateAttitude(leanMotion(degrees: 0),
                                             locationSnapshot: makeLocation(course: 0))

        // Then: 일시정지 전 에피소드가 재개 후로 새어 나오지 않아야 함
        // (실주행에서는 정차 조건이 pause보다 먼저 플러시하므로 유실이 아니라 중복 방지)
        XCTAssertNil(afterResume.event,
                     "pause로 폐기된 에피소드가 재개 후 방출되면 안 됩니다")
    }
}
