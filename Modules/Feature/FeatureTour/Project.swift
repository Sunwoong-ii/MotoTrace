import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeature(
    name: ModuleName.featureTour.rawValue,
    interfaceDependencies: [
        .makeInterfaceDependency(name: .coreSensors),
        .makeInterfaceDependency(name: .coreTracking)
    ]
)
