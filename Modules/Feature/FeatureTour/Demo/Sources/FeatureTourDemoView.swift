import SwiftUI
import AppDI
import CoreSensors
import CoreTracking
import CoreDataStorage
import FeatureTour
import FeatureTourInterface

struct FeatureTourDemoView: View {
    private let container: AppDIContainer
    
    init() {
        let container = AppDIContainer()
        
        // Demo용 DI 설정 (Assembly 사용)
        CoreSensorsAssembly.register(in: container)
        CoreTrackingAssembly.register(in: container)
        CoreDataStorageAssembly.register(in: container)
        
        self.container = container
    }
    
    var body: some View {
        TourAssembler.assemble(
            container: container,
            initialState: TourState()
        )
    }
}
