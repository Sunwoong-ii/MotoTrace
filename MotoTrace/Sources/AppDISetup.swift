//
//  AppDISetup.swift
//  MotoTrace
//
//  Created by Woong on 2026/01/23.
//

import AppDI
import CoreSensors
import CoreTracking
import CoreDataStorage
import Foundation

/// Production 환경 DI 조립
enum AppDISetup {
    static func production() -> AppDIContainer {
        let container = AppDIContainer()
        
        // 각 모듈의 Assembly를 통해 의존성 등록
        CoreSensorsAssembly.register(in: container)
        CoreTrackingAssembly.register(in: container)
        CoreDataStorageAssembly.register(in: container)
        
        return container
    }
}

// MARK: - 테스트용 예시
/*
 테스트에서 Mock 주입 예시:
 
 func testWithMockSensors() {
     let container = AppDIContainer()
     
     // Production Assembly로 기본 등록
     CoreSensorsAssembly.register(in: container)
     CoreTrackingAssembly.register(in: container)
     CoreDataStorageAssembly.register(in: container)
     
     // 필요한 것만 Mock으로 override
     container.register(CoreSensorsInterface.self, scope: .singleton) {
         MockSensorsService()
     }
     
     // 사용
     let view = TourFeatureAssembler.assemble(
         container: container,
         initialState: RidingState()
     )
 }
 */
