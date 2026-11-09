import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: ModuleName.coreDataStorage.rawValue,
    interfaceDependencies: [
        // 임계값 저장소가 TrackingThresholds를 그대로 영속화한다
        .makeInterfaceDependency(name: .coreTracking)
    ]
)
