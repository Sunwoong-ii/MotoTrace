import ProjectDescription

public extension Project {
    static func makeModule(
        name: String,
        interfaceDependencies: [TargetDependency] = [],
        implementationDependencies: [TargetDependency] = []
    ) -> Project {
        let defaultImplementationDependencies: [TargetDependency] = [
            .target(name: "\(name)Interface")
        ]
        let resolvedImplementationDependencies = defaultImplementationDependencies + implementationDependencies

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
        let featureInterfaceDependencies = interfaceDependencies + [.sharedInterface]
        
        return makeModule(
            name: name,
            interfaceDependencies: featureInterfaceDependencies,
            implementationDependencies: implementationDependencies
        )
    }
}
