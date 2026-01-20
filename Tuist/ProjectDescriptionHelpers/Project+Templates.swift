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
            .target(name: "\(name)Interface"),
            .makeDependency(name: .shared)
        ]
        
        let resolvedImplementationDependencies = defaultImplementationDependencies + implementationDependencies
        let interfaceDependencies = interfaceDependencies + [.makeDependency(name: .shared)]

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
                    dependencies: interfaceDependencies
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
