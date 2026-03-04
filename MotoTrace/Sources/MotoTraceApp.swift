import SwiftUI
import AppDI
import SwiftData

@main
struct MotoTraceApp: App {
    let setup = AppDISetup.production()
    
    var body: some Scene {
        WindowGroup {
            RootTabView(container: setup.container)
        }
        .modelContainer(setup.modelContainer)
    }
}
