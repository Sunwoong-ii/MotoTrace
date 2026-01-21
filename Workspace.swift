import ProjectDescription

let workspace = Workspace(
    name: "MotoTrace",
    projects: [
        "Modules/SharedModules/Shared",
        "Modules/Core/CoreDataStorage",
        "Modules/Core/CoreTracking",
        "Modules/Feature/FeatureTour",
        "Modules/Feature/FeatureHistory",
        "Modules/Feature/FeatureSettings",
        "MotoTrace"
    ]
)
