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
    func locationStream() -> AsyncStream<Location>
    func motionStream() -> AsyncStream<Motion>
}
