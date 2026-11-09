import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeature(
    name: ModuleName.featureSettings.rawValue,
    interfaceDependencies: [
        // SettingsState가 TrackingThresholds와 LocationAuthorizationStatus를 참조한다
        .makeInterfaceDependency(name: .coreTracking),
        .makeInterfaceDependency(name: .coreSensors)
    ],
    implementationDependencies: [
        // Store가 임계값 저장소를 주입받는다
        .makeInterfaceDependency(name: .coreDataStorage)
    ]
)
