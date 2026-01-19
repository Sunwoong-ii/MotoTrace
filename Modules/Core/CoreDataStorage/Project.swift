import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: ModuleName.coreDataStorage,
    interfaceDependencies: [
        .sharedInterface
    ],
    implementationDependencies: [
        .shared
    ]
)
