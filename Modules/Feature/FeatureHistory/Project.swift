import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeature(
    name: ModuleName.featureHistory,
    interfaceDependencies: [
        .coreDataStorageInterface
    ]
)
