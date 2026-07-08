//
//  CoreSensorsAssembly.swift
//  CoreSensors
//
//  Created by Woong on 2026/01/23.
//

import AppDI
import CoreSensorsInterface
import Foundation
import Shared

/// CoreSensors DI 등록
public enum CoreSensorsAssembly: DIAssembly {
    public static func register(in container: AppDIContainer) {
        container.register(CoreSensorsInterface.self, scope: .singleton) { () -> CoreSensorsInterface in
            #if DEBUG
            // Mock 센서: 라이딩 없이 가상 주행 데이터로 전체 플로우 테스트 (MotoTrace-MockRide 스킴)
            if LaunchFlags.useMockSensors {
                return MockCoreSensorsService()
            }
            #endif
            return CoreSensorsService()
        }
    }
}
