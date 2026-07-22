//  MockCoreSensorsService.swift
//  CoreSensors
//
//  Created by Woong on 2026/07/08.
//

#if DEBUG
import Foundation
import CoreSensorsInterface

/// `-UseMockSensors` 런치 인자로 주입되는 가상 센서.
/// 실제 라이딩 없이 시뮬레이터에서 트래킹 전체 플로우(분석·이벤트·저장·세션복구)를
/// 검증하기 위해 MockRideScenario를 실시간 재생한다.
internal final class MockCoreSensorsService: CoreSensorsInterface {
    // 지도에서 그럴듯하게 보이도록 실제 도로(북한강로) 인근에서 출발
    private static let startLatitude = 37.5665
    private static let startLongitude = 127.3066

    private let scenario: MockRideScenario
    private let locationInterval: TimeInterval
    private let motionInterval: TimeInterval

    private var locationContinuation: AsyncStream<Location>.Continuation?
    private var motionContinuation: AsyncStream<Motion>.Continuation?
    private var locationStreamValue: AsyncStream<Location>
    private var motionStreamValue: AsyncStream<Motion>

    // 재생 상태 — stop()은 시나리오 시간을 동결하고, resume()은 그 지점부터 이어서 재생
    private var frozenOffset: TimeInterval = 0
    private var playbackStartDate: Date?
    private var locationTask: Task<Void, Never>?
    private var motionTask: Task<Void, Never>?

    // dead reckoning 좌표 — 루프를 돌아도 리셋하지 않고 계속 적분해 지도 순간이동 방지
    private var latitude = MockCoreSensorsService.startLatitude
    private var longitude = MockCoreSensorsService.startLongitude
    private var lastIntegratedElapsed: TimeInterval = 0

    private var lastMotion: Motion?

    /// 주기는 실제 센서와 동일 (GPS ≈ 1Hz, CMDeviceMotion 0.2초) — 테스트에서 단축 주입 가능
    init(
        scenario: MockRideScenario = MockRideScenario(),
        locationInterval: TimeInterval = 1.0,
        motionInterval: TimeInterval = 0.2
    ) {
        self.scenario = scenario
        self.locationInterval = locationInterval
        self.motionInterval = motionInterval

        let (locStream, locCont) = AsyncStream.makeStream(of: Location.self)
        locationStreamValue = locStream
        locationContinuation = locCont

        let (motStream, motCont) = AsyncStream.makeStream(of: Motion.self)
        motionStreamValue = motStream
        motionContinuation = motCont
    }

    // 시뮬레이터에서 권한 팝업 없이 전체 플로우가 진행되도록 no-op
    func requestWhenInUseAuthorization() {}
    func requestAlwaysAuthorization() {}

    func start() {
        // 실제 구현과 동일한 시맨틱: 재시작 시마다 스트림 재생성 (이전 소비자 finish)
        let (locStream, locCont) = AsyncStream.makeStream(of: Location.self)
        locationContinuation?.finish()
        locationStreamValue = locStream
        locationContinuation = locCont

        let (motStream, motCont) = AsyncStream.makeStream(of: Motion.self)
        motionContinuation?.finish()
        motionStreamValue = motStream
        motionContinuation = motCont

        // 새 세션은 시나리오 처음(정차·직립)부터 — 린앵글 영점 캘리브레이션이 항상 직립에서 잡힘
        stopPlayback()
        frozenOffset = 0
        lastIntegratedElapsed = 0
        latitude = Self.startLatitude
        longitude = Self.startLongitude
        startPlayback()
    }

    func stop() {
        frozenOffset = currentElapsed()
        stopPlayback()
    }

    /// 실제 구현과 동일한 시맨틱: 기존 스트림 유지, 동결된 시나리오 시간부터 이어서 재생
    func resume() {
        guard playbackStartDate == nil else { return }
        startPlayback()
    }

    func speedLocationStream() -> AsyncStream<Location> {
        locationStreamValue
    }

    func motionStream() -> AsyncStream<Motion> {
        motionStreamValue
    }

    func currentMotion() -> Motion? {
        lastMotion
    }

    // MARK: - 재생 루프

    private func startPlayback() {
        playbackStartDate = Date()

        locationTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.emitLocation()
                try? await Task.sleep(for: .seconds(self.locationInterval))
            }
        }

        motionTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.emitMotion()
                try? await Task.sleep(for: .seconds(self.motionInterval))
            }
        }
    }

    private func stopPlayback() {
        locationTask?.cancel()
        motionTask?.cancel()
        locationTask = nil
        motionTask = nil
        playbackStartDate = nil
    }

    /// 누적 시나리오 시간 — 일시정지 구간은 자동으로 제외됨
    private func currentElapsed() -> TimeInterval {
        guard let startDate = playbackStartDate else { return frozenOffset }
        return frozenOffset + Date().timeIntervalSince(startDate)
    }

    private func currentSample() -> RideSample {
        let t = currentElapsed().truncatingRemainder(dividingBy: scenario.loopDuration)
        return scenario.sample(at: t)
    }

    private func emitLocation() {
        let elapsed = currentElapsed()
        let sample = currentSample()

        // dead reckoning: 마지막 적분 시점 이후 경과분만큼 좌표 전진
        let dt = elapsed - lastIntegratedElapsed
        lastIntegratedElapsed = elapsed
        if dt > 0 {
            let metersPerSec = sample.speedKmh / 3.6
            let headingRad = sample.headingDegrees * .pi / 180
            // 위도 1도 ≈ 111,320m. 경도는 위도에 따라 축소
            latitude += metersPerSec * dt * cos(headingRad) / 111_320
            longitude += metersPerSec * dt * sin(headingRad) / (111_320 * cos(latitude * .pi / 180))
        }

        // timestamp는 벽시계 — 분석기가 실제 시각 기준으로 Δt·경과시간을 계산하기 때문
        // course는 항상 유효값(≥0) — LeanAngleAnalyzer가 course < 0이면 린앵글을 갱신하지 않음
        locationContinuation?.yield(
            Location(
                latitude: latitude,
                longitude: longitude,
                speedKmh: sample.speedKmh,
                horizontalAccuracy: 5.0,
                timestamp: Date(),
                course: sample.headingDegrees
            )
        )
    }

    private func emitMotion() {
        let sample = currentSample()
        let attitude = MockAttitudeFactory.attitude(
            headingDegrees: sample.headingDegrees,
            leanDegrees: sample.leanDegrees,
            pitchDegrees: sample.pitchDegrees
        )

        // roll/pitch/yaw는 표시용 근사값 — 분석기는 gravity·quaternion만 사용
        let motion = Motion(
            rollDegrees: sample.leanDegrees,
            pitchDegrees: sample.pitchDegrees,
            yawDegrees: -sample.headingDegrees,
            userAccelerationX: 0,
            userAccelerationY: 0,
            userAccelerationZ: 0,
            timestamp: Date(),
            gravityX: attitude.gravityX,
            gravityY: attitude.gravityY,
            gravityZ: attitude.gravityZ,
            quaternionW: attitude.quaternionW,
            quaternionX: attitude.quaternionX,
            quaternionY: attitude.quaternionY,
            quaternionZ: attitude.quaternionZ
        )
        lastMotion = motion
        motionContinuation?.yield(motion)
    }
}
#endif
