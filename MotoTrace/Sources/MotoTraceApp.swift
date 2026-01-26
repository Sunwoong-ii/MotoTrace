import SwiftUI
import AppDI
import SwiftData

@main
struct MotoTraceApp: App {
    let setup = AppDISetup.production()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            // Feature에서 container를 받아 resolve 사용:
            // let sensors = setup.container.resolve(CoreSensorsInterface.self)
        }
        .modelContainer(setup.modelContainer)
    }
}
