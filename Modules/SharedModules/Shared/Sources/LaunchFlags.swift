//  LaunchFlags.swift
//  Shared
//
//  Created by Woong on 2026/07/08.
//

import Foundation

/// 런치 인자 기반 디버그 플래그 — 모듈 간 문자열 중복 없이 한 곳에서 판별
public enum LaunchFlags {
    /// `-UseMockSensors`: 가상 주행 데이터로 트래킹을 테스트하는 Mock 센서 모드
    /// Release 빌드에서는 항상 false — Mock 코드 경로가 프로덕션에서 활성화되지 않도록
    public static var useMockSensors: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-UseMockSensors")
        #else
        false
        #endif
    }
}
