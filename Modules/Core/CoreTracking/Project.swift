import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: ModuleName.coreTracking.rawValue,
    implementationDependencies: [
        .makeInterfaceDependency(name: .coreSensors)
    ]
)
