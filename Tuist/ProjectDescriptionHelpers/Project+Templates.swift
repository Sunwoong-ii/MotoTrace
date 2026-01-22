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
        return Project(
            name: name,
            targets: makeModuleTargets(
                name: name,
                interfaceDependencies: interfaceDependencies,
                implementationDependencies: implementationDependencies
            )
        )
    }

    static func makeFeature(
        name: String,
        interfaceDependencies: [TargetDependency] = [],
        implementationDependencies: [TargetDependency] = [],
        includeDemo: Bool = true
    ) -> Project {
        let moduleTargets = makeModuleTargets(
            name: name,
            interfaceDependencies: interfaceDependencies,
            implementationDependencies: implementationDependencies
        )

        let demoTargets: [Target]
        if includeDemo {
            let resolvedDemoDependencies = unique(
                [.target(name: name)] +
                interfaceDependencies +
                implementationDependencies
            )
            
            demoTargets = [
                .target(
                    name: "\(name)Demo",
                    destinations: .iOS,
                    product: .app,
                    bundleId: "\(BuildSettings.bundleIdPrefix).\(name)Demo",
                    deploymentTargets: BuildSettings.deploymentTargets,
                    infoPlist: .extendingDefault(with: AppInfoPlist.base),
                    sources: ["Demo/Sources/**"],
                    dependencies: resolvedDemoDependencies
                )
            ]
        } else {
            demoTargets = []
        }

        return Project(
            name: name,
            targets: moduleTargets + demoTargets
        )
    }
    
    private static func makeModuleTargets(
        name: String,
        interfaceDependencies: [TargetDependency],
        implementationDependencies: [TargetDependency]
    ) -> [Target] {
        let defaultImplementationDependencies: [TargetDependency] = [
            .target(name: "\(name)Interface")
        ]

        let resolvedInterfaceDependencies = interfaceDependencies + [.makeDependency(name: .shared)]
        
        let resolvedImplementationDependencies = unique(
            defaultImplementationDependencies +
            resolvedInterfaceDependencies +
            implementationDependencies
        )
        
        return [
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
    }

    private static func unique(_ dependencies: [TargetDependency]) -> [TargetDependency] {
        var dependency = Set<TargetDependency>()
        return dependencies.filter { dependency.insert($0).inserted }
    }
}
