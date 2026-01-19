import ProjectDescription

public extension TargetDependency {
    static let sharedInterface: Self = .project(
        target: "\(ModuleName.shared)Interface",
        path: .relativeToRoot("Modules/SharedModules/Shared")
    )
    
    static let shared: Self = .project(
        target: ModuleName.shared,
        path: .relativeToRoot("Modules/SharedModules/Shared")
    )
    
    static let coreDataStorageInterface: Self = .project(
        target: "\(ModuleName.coreDataStorage)Interface",
        path: .relativeToRoot("Modules/Core/CoreDataStorage")
    )
    
    static let coreTrackingInterface: Self = .project(
        target: "\(ModuleName.coreTracking)Interface",
        path: .relativeToRoot("Modules/Core/CoreTracking")
    )
}
