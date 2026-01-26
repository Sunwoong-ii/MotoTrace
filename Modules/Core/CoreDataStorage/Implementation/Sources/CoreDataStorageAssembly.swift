//
//  CoreDataStorageAssembly.swift
//  CoreDataStorage
//
//  Created by Woong on 2026/01/23.
//

import AppDI
import CoreDataStorageInterface
import Foundation
import SwiftData

/// CoreDataStorage DI 등록
public enum CoreDataStorageAssembly: DIAssembly {
    public static func register(in container: AppDIContainer) {
        // TourRepository (파라미터: ModelContainer)
        container.register(TourRepositoryInterface.self, scope: .singleton) { (modelContainer: ModelContainer) in
            TourRepository(modelContainer: modelContainer)
        }
    }
}
