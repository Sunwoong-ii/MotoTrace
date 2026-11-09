import SwiftUI
import AppDI
import CoreSensors
import CoreTracking
import CoreDataStorage
import FeatureSettings

struct FeatureSettingsDemoView: View {
    private let container: AppDIContainer

    init() {
        let container = AppDIContainer()
        CoreSensorsAssembly.register(in: container)
        CoreTrackingAssembly.register(in: container)
        CoreDataStorageAssembly.register(in: container)
        self.container = container
    }

    var body: some View {
        SettingsAssembler.assemble(container: container)
    }
}
