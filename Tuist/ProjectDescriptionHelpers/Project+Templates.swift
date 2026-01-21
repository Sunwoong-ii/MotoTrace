import ProjectDescription

public extension Project {
    static func makeSingleModule(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Project {
        Project(
            name: name,
            targets: [
                .target(
                    name: name,
                    destinations: .iOS,
                    product: .staticFramework,
                    bundleId: "\(BuildSettings.bundleIdPrefix).\(name)",
                    deploymentTargets: BuildSettings.deploymentTargets,
                    sources: ["Sources/**"],
                    dependencies: dependencies
                )
            ]
        )
    }

    static func makeModule(
        name: String,
        interfaceDependencies: [TargetDependency] = [],
        implementationDependencies: [TargetDependency] = []
    ) -> Project {
        let defaultImplementationDependencies: [TargetDependency] = [
            .target(name: "\(name)Interface")
        ]

        let resolvedInterfaceDependencies = interfaceDependencies + [.makeDependency(name: .shared)]
        let resolvedImplementationDependencies =
            defaultImplementationDependencies + resolvedInterfaceDependencies + implementationDependencies

        return Project(
            name: name,
            targets: [
                .target(
                    name: "\(name)Interface",
                    destinations: .iOS,
                    product: .staticFramework,
                    bundleId: "\(BuildSettings.bundleIdPrefix).\(name)Interface",
                    deploymentTargets: BuildSettings.deploymentTargets,
                    sources: ["Interface/Sources/**"],
                    dependencies: resolvedInterfaceDependencies
                ),
                .target(
                    name: name,
                    destinations: .iOS,
                    product: .staticFramework,
                    bundleId: "\(BuildSettings.bundleIdPrefix).\(name)",
                    deploymentTargets: BuildSettings.deploymentTargets,
                    sources: ["Implementation/Sources/**"],
                    dependencies: resolvedImplementationDependencies
                )
            ]
        )
    }

    static func makeFeature(
        name: String,
        interfaceDependencies: [TargetDependency] = [],
        implementationDependencies: [TargetDependency] = []
    ) -> Project {
        return makeModule(
            name: name,
            interfaceDependencies: interfaceDependencies,
            implementationDependencies: implementationDependencies
        )
    }
}
