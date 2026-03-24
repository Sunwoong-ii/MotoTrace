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
    
    private var locationContinuation: AsyncStream<Location>.Continuation?
    private var motionContinuation: AsyncStream<Motion>.Continuation?
    private var locationStreamValue: AsyncStream<Location>
    private var motionStreamValue: AsyncStream<Motion>
    
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
        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] (motion: CMDeviceMotion?, _) in
            guard let motion else { return }
            
            // radian -> degree
            let roll = motion.attitude.roll * 180.0 / .pi
            let pitch = motion.attitude.pitch * 180.0 / .pi
            let yaw = motion.attitude.yaw * 180.0 / .pi
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let speedMetersPerSecond = max(location.speed, 0)
        
        // m/s -> km/h
        let speedKmh = speedMetersPerSecond * 3.6
        // course: 유효하지 않으면 -1
        let course = location.course >= 0 ? location.course : -1
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
