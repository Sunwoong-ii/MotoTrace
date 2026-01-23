import ProjectDescription

public enum ModuleType {
    case feature
    case core
    case shared
    case di
    
    public var path: String {
        switch self {
        case .feature: "Modules/Feature/"
        case .core: "Modules/Core/"
        case .shared: "Modules/SharedModules/"
        case .di: "Modules/DI/"
        }
    }
}

public enum ModuleName: String, CaseIterable {
    // MARK: - Shared
    case shared = "Shared"
    
    // MARK: - Core
    case coreDataStorage = "CoreDataStorage"
    case coreTracking = "CoreTracking"
    case coreSensors = "CoreSensors"
    
    // MARK: - DI
    case appDI = "AppDI"
    
    // MARK: - Feature
    case featureTour = "FeatureTour"
    case featureHistory = "FeatureHistory"
    case featureSettings = "FeatureSettings"
    
    public var type: ModuleType {
        switch self {
        case .shared: .shared
            
        case .coreDataStorage: .core
        case .coreTracking: .core
        case .coreSensors: .core
            
        case .appDI: .di
            
        case .featureTour: .feature
        case .featureHistory: .feature
        case .featureSettings: .feature
        }
    }
    
    public var path: String {
        type.path + "/" + self.rawValue
    }
    
    public static var allDependencies: [TargetDependency] {
        ModuleName.allCases.map { (moduleName: ModuleName) -> TargetDependency in
            return moduleName.dependency
        }
    }
    
    public var dependency: TargetDependency {
        return TargetDependency.makeDependency(name: self)
    }
    
    public var interfaceDependency: TargetDependency {
        return TargetDependency.makeInterfaceDependency(name: self)
    }
}
