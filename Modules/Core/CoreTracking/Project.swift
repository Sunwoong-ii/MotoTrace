import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: ModuleName.coreTracking,
    interfaceDependencies: [
        .sharedInterface
    ],
    implementationDependencies: [
        .shared
    ]
)
