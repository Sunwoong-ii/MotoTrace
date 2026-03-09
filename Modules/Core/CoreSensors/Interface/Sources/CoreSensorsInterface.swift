//
//  CoreSensorsInterface.swift
//  CoreSensorsInterface
//
//  Created by 웅 on 1/20/26.
//

import Foundation

public protocol CoreSensorsInterface {
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func start()
    func stop()
    func speedLocationStream() -> AsyncStream<Location>
    func motionStream() -> AsyncStream<Motion>
    
    func currentMotion() -> Motion?
}
