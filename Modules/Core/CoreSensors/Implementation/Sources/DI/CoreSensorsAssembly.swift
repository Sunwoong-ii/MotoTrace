//
//  CoreSensorsAssembly.swift
//  CoreSensors
//
//  Created by Woong on 2026/01/23.
//

import AppDI
import CoreSensorsInterface
import Foundation

/// CoreSensors DI 등록
public enum CoreSensorsAssembly: DIAssembly {
    public static func register(in container: AppDIContainer) {
        container.register(CoreSensorsInterface.self, scope: .singleton) {
            CoreSensorsService()
        }
    }
}
