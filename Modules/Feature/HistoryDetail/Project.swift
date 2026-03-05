import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeature(
    name: "HistoryDetail",
    implementationDependencies: [
        .makeDependency(name: .coreDataStorage)
    ]
)
