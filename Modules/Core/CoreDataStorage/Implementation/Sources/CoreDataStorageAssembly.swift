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

public enum CoreDataStorageAssembly: DIAssembly {
    public static func register(in container: AppDIContainer) {
        container.register(TourRepositoryInterface.self, scope: .singleton) {
            let modelContainer = container.resolve(ModelContainer.self)
            return TourRepository(modelContainer: modelContainer)
        }
        container.register(TrackingSessionRepositoryInterface.self, scope: .singleton) {
            TrackingSessionRepository()
        }
    }
}
