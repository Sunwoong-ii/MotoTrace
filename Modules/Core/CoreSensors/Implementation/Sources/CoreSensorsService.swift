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
    private lazy var locationStreamValue: AsyncStream<Location> = {
        AsyncStream { continuation in
            self.locationContinuation = continuation
        }
    }()
    private lazy var motionStreamValue: AsyncStream<Motion> = {
        AsyncStream { continuation in
            self.motionContinuation = continuation
        }
    }()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .fitness
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
            self?.motionContinuation?.yield(
                Motion(
                    rollDegrees: roll,
                    pitchDegrees: pitch,
                    yawDegrees: yaw,
                    userAccelerationX: acceleration.x,
                    userAccelerationY: acceleration.y,
                    userAccelerationZ: acceleration.z,
                    timestamp: Date()
                )
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let speedMetersPerSecond = max(location.speed, 0)
        
        // m/s -> km/h
        let speedKmh = speedMetersPerSecond * 3.6
        locationContinuation?.yield(
            Location(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                speedKmh: speedKmh,
                horizontalAccuracy: location.horizontalAccuracy,
                timestamp: location.timestamp
            )
        )
    }
}
