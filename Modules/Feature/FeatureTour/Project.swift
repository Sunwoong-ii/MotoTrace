import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeature(
    name: ModuleName.featureTour.rawValue,
    implementationDependencies: [
        .makeInterfaceDependency(name: .coreSensors),
        .makeInterfaceDependency(name: .coreTracking)
    ]
)
