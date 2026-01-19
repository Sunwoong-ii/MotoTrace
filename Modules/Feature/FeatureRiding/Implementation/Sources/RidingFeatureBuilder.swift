import SwiftUI
import FeatureRidingInterface

/// 라이딩 Feature Builder
public enum RidingFeatureBuilder: RidingFeatureBuilding {
    public static func build() -> AnyView {
        AnyView(RidingView())
    }
}
