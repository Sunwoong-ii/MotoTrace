import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeature(
    name: ModuleName.featureHistory.rawValue,
    implementationDependencies: [
        .makeDependency(name: .coreDataStorage),
        .makeDependency(name: .historyDetail)
    ]
)
