import SwiftUI
import FeatureTour
import FeatureTourInterface
import CoreSensorsInterface
import CoreTrackingInterface

struct FeatureTourDemoView: View {
    private let dependencies: TourDependencies = TourDependencies(
        sensors: CoreSensorsFactory.create(),
        analyzer: TrackingAnalyzerFactory.create()
    )
    
    var body: some View {
        TourFeatureAssembler.assemble(dependencies: dependencies)
    }
}
