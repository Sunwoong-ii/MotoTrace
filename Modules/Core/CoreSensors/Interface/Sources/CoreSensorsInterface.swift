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
    func start()   // 새 세션 시작 — 스트림 재생성 포함
    func stop()    // 센서 중단 (스트림 유지)
    func resume()  // 일시정지 후 재개 — 기존 스트림 유지, 센서만 재시작
    func speedLocationStream() -> AsyncStream<Location>
    func motionStream() -> AsyncStream<Motion>
    
    func currentMotion() -> Motion?
}
