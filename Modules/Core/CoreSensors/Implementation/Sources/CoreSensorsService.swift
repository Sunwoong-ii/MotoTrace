//  CoreSensorsService.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/20.
//

import CoreLocation
import CoreMotion
import Foundation
import CoreSensorsInterface

internal final class CoreSensorsService: NSObject, CoreSensorsInterface, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()

    // 백그라운드 수집 검증용 계측 (docs/BACKLOG.md)
    private let instrumentation = CoreSensorsInstrumentation()
    
    private var locationContinuation: AsyncStream<Location>.Continuation?
    private var motionContinuation: AsyncStream<Motion>.Continuation?
    private var locationStreamValue: AsyncStream<Location>
    private var motionStreamValue: AsyncStream<Motion>

    // 권한 스트림은 start()/stop()과 무관하게 유지된다 (센서 스트림과 달리 세션이 아니라 앱 단위 관심사).
    // 다만 구독 시마다 새로 발급한다 — AsyncStream은 소비자가 하나뿐이라, 이전 구독이 끝난 뒤
    // 같은 스트림을 넘기면 새 구독자가 즉시 종료된 스트림을 받아 권한 변화를 놓친다
    private var authorizationContinuation: AsyncStream<LocationAuthorizationStatus>.Continuation?
    
    override init() {
        // 초기 스트림 생성
        let (locStream, locCont) = AsyncStream.makeStream(of: Location.self)
        locationStreamValue = locStream
        locationContinuation = locCont
        
        let (motStream, motCont) = AsyncStream.makeStream(of: Motion.self)
        motionStreamValue = motStream
        motionContinuation = motCont

        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .fitness
        
        // 백그라운드 추적 필수 옵션
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        motionQueue.qualityOfService = .userInitiated
        motionManager.deviceMotionUpdateInterval = 0.2
    }
    
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func authorizationStatus() -> LocationAuthorizationStatus {
        Self.map(locationManager.authorizationStatus)
    }

    func authorizationStream() -> AsyncStream<LocationAuthorizationStatus> {
        // 이전 구독은 정리하고 새로 발급 — 센서 스트림의 start()와 같은 방식
        let (stream, continuation) = AsyncStream.makeStream(of: LocationAuthorizationStatus.self)
        authorizationContinuation?.finish()
        authorizationContinuation = continuation
        // 구독 시점에 현재 값을 흘려 UI가 첫 프레임부터 올바른 상태를 갖게 한다
        continuation.yield(authorizationStatus())
        return stream
    }

    /// restricted는 사용자가 스스로 풀 수 없는 경우도 있지만, 안내·차단 처리는 denied와 같으므로 통합한다
    private static func map(_ status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .denied, .restricted: .denied
        case .authorizedWhenInUse: .whenInUse
        case .authorizedAlways: .always
        @unknown default: .denied
        }
    }
    
    func start() {
        // 재시작 시마다 새 스트림 생성 — 이전 Task가 취소된 후에도 새 소비자가 값을 받을 수 있음
        let (locStream, locCont) = AsyncStream.makeStream(of: Location.self)
        locationContinuation?.finish()
        locationStreamValue = locStream
        locationContinuation = locCont
        
        let (motStream, motCont) = AsyncStream.makeStream(of: Motion.self)
        motionContinuation?.finish()
        motionStreamValue = motStream
        motionContinuation = motCont
        
        locationManager.startUpdatingLocation()
        startMotionUpdates()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        motionManager.stopDeviceMotionUpdates()
    }
    
    /// 일시정지 후 재개 — 기존 AsyncStream continuation을 유지한 채 센서만 재시작
    /// start() 를 호출하면 continuation이 finish되어 타스크 루프가 빠져나가는 버그 발생
    func resume() {
        locationManager.startUpdatingLocation()
        startMotionUpdates()
    }
    
    func speedLocationStream() -> AsyncStream<Location> {
        locationStreamValue
    }
    
    func motionStream() -> AsyncStream<Motion> {
        motionStreamValue
    }
    
    func currentMotion() -> Motion? {
        guard let motion = motionManager.deviceMotion else { return nil }
        return Motion(
            rollDegrees: motion.attitude.roll * 180.0 / .pi,
            pitchDegrees: motion.attitude.pitch * 180.0 / .pi,
            yawDegrees: motion.attitude.yaw * 180.0 / .pi,
            userAccelerationX: motion.userAcceleration.x,
            userAccelerationY: motion.userAcceleration.y,
            userAccelerationZ: motion.userAcceleration.z,
            timestamp: Date()
        )
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        // xTrueNorthZVertical: world-x = 진북, world-y = 서, world-z = 위(NWU 프레임)
        // GPS heading이 True North 기준이므로 레퍼런스 프레임을 맞춰야 언덕 분리가 정확함
        motionManager.startDeviceMotionUpdates(
            using: .xTrueNorthZVertical,
            to: motionQueue
        ) { [weak self] (motion: CMDeviceMotion?, _) in
            guard let motion else { return }

            // radian -> degree
            let roll = motion.attitude.roll * 180.0 / .pi
            let pitch = motion.attitude.pitch * 180.0 / .pi
            let yaw = motion.attitude.yaw * 180.0 / .pi

            self?.instrumentation.recordMotionCallback(rollDegrees: roll, yawDegrees: yaw)
            let acceleration = motion.userAcceleration
            let gravity = motion.gravity
            let q = motion.attitude.quaternion
            self?.motionContinuation?.yield(
                Motion(
                    rollDegrees: roll,
                    pitchDegrees: pitch,
                    yawDegrees: yaw,
                    userAccelerationX: acceleration.x,
                    userAccelerationY: acceleration.y,
                    userAccelerationZ: acceleration.z,
                    timestamp: Date(),
                    gravityX: gravity.x,
                    gravityY: gravity.y,
                    gravityZ: gravity.z,
                    quaternionW: q.w,
                    quaternionX: q.x,
                    quaternionY: q.y,
                    quaternionZ: q.z
                )
            )
        }
    }
    
    /// 설정 앱에서 권한을 바꾸고 돌아왔을 때도 발화한다 — 화면 안내를 실시간으로 갱신하는 경로
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationContinuation?.yield(Self.map(manager.authorizationStatus))
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let speedMetersPerSecond = max(location.speed, 0)
        
        // m/s -> km/h
        let speedKmh = speedMetersPerSecond * 3.6
        // course: 유효하지 않으면 -1
        let course = location.course >= 0 ? location.course : -1

        instrumentation.recordLocationCallback(
            speedKmh: speedKmh,
            horizontalAccuracy: location.horizontalAccuracy
        )
        locationContinuation?.yield(
            Location(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                speedKmh: speedKmh,
                horizontalAccuracy: location.horizontalAccuracy,
                timestamp: location.timestamp,
                course: course
            )
        )
    }
}
