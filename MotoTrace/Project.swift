import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Constants
private let appName = "MotoTrace"
private let bundleId = BuildSettings.bundleIdPrefix

// MARK: - Project
let project = Project(
    name: appName,
    targets: [
        .target(
            name: appName,
            destinations: .iOS,
            product: .app,
            bundleId: bundleId,
            deploymentTargets: BuildSettings.deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                // Feature
                .project(target: "FeatureRiding", path: .relativeToRoot("Modules/Feature/FeatureRiding")),
                .project(target: "FeatureHistory", path: .relativeToRoot("Modules/Feature/FeatureHistory")),
                .project(target: "FeatureSettings", path: .relativeToRoot("Modules/Feature/FeatureSettings")),
                // Core
                .project(target: "CoreDataStorage", path: .relativeToRoot("Modules/Core/CoreDataStorage")),
                .project(target: "CoreTracking", path: .relativeToRoot("Modules/Core/CoreTracking")),
                // Shared
                .project(target: "Shared", path: .relativeToRoot("Modules/SharedModules/Shared"))
            ]
        ),
        .target(
            name: "\(appName)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundleId)Tests",
            deploymentTargets: BuildSettings.deploymentTargets,
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: appName)
            ]
        )
    ]
)
