//
//  CoreDataStorageAssembly.swift
//  CoreDataStorage
//
//  Created by Woong on 2026/01/23.
//

import AppDI
import CoreDataStorageInterface
import Foundation

/// CoreDataStorage DI 등록
public enum CoreDataStorageAssembly: DIAssembly {
    public static func register(in container: AppDIContainer) {
        container.register(DataStorageServiceInterface.self, scope: .singleton) {
            DataStorageService()
        }
    }
}
