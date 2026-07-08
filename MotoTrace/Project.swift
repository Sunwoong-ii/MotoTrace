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
            destinations: BuildSettings.destinations,
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
            destinations: BuildSettings.destinations,
            product: .unitTests,
            bundleId: "\(bundleId)Tests",
            deploymentTargets: BuildSettings.deploymentTargets,
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: appName)
            ]
        )
    ],
    // 스킴은 gitignore 대상(.xcodeproj)이라 Xcode에서 고치면 유실됨 — manifest에 명시해 유지
    schemes: [
        // 기본 스킴: 명시적으로 정의하는 순간 자동 생성 스킴을 대체하므로 빌드/테스트 액션 보존
        .scheme(
            name: appName,
            shared: true,
            buildAction: .buildAction(targets: ["\(appName)"]),
            testAction: .targets(["\(appName)Tests"]),
            runAction: .runAction(
                executable: "\(appName)",
                arguments: .arguments(launchArguments: [
                    .launchArgument(name: "-UseMockSensors", isEnabled: false)
                ])
            )
        ),
        // 가상 주행 스킴: Mock 센서가 시나리오를 재생 — 라이딩 없이 트래킹 플로우 검증용
        .scheme(
            name: "\(appName)-MockRide",
            shared: true,
            buildAction: .buildAction(targets: ["\(appName)"]),
            runAction: .runAction(
                configuration: .debug,
                executable: "\(appName)",
                arguments: .arguments(launchArguments: [
                    .launchArgument(name: "-UseMockSensors", isEnabled: true)
                ])
            )
        )
    ]
)
