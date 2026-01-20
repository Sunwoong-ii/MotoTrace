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
                with: AppInfoPlist.base
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: ModuleName.allDependencies
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
