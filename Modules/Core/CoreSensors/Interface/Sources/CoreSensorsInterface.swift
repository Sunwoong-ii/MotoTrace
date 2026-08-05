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

    func authorizationStatus() -> LocationAuthorizationStatus
    /// 권한 변화 스트림 — 설정 앱에서 권한을 바꾸고 돌아오는 경로를 잡으려면 폴링이 아니라 관찰이 필요하다.
    /// 구독 즉시 현재 상태를 한 번 방출한다
    func authorizationStream() -> AsyncStream<LocationAuthorizationStatus>
    func start()   // 새 세션 시작 — 스트림 재생성 포함
    func stop()    // 센서 중단 (스트림 유지)
    func resume()  // 일시정지 후 재개 — 기존 스트림 유지, 센서만 재시작
    func speedLocationStream() -> AsyncStream<Location>
    func motionStream() -> AsyncStream<Motion>
    
    func currentMotion() -> Motion?
}
