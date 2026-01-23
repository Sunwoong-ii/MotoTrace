import SwiftUI
import AppDI

@main
struct MotoTraceApp: App {
    let container = AppDISetup.production()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            // Feature에서 container를 받아 resolve 사용:
            // let sensors = container.resolve(CoreSensorsInterface.self)
        }
    }
}
