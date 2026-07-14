import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeature(
    name: ModuleName.featureTour.rawValue,
    interfaceDependencies: [
        .makeInterfaceDependency(name: .coreSensors),
        .makeInterfaceDependency(name: .coreTracking)
    ],
    implementationDependencies: [
        // TourStore·TourAssembler가 import — 미선언 시 빌드 경고 발생
        .makeInterfaceDependency(name: .coreDataStorage)
    ]
)
