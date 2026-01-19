import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeature(
    name: ModuleName.featureRiding,
    interfaceDependencies: [
        .coreDataStorageInterface,
        .coreTrackingInterface
    ]
)
