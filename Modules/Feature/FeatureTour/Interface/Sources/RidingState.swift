import Foundation
import MapKit
import SwiftUI
import CoreLocation

/// 라이딩 Feature의 State (MVI 패턴)
public struct RidingState {
    public var isRiding: Bool
    public var cameraPosition: MapCameraPosition
    
    public init(isRiding: Bool = false,
                cameraPosition: MapCameraPosition = .automatic) {
        self.isRiding = isRiding
        self.cameraPosition = cameraPosition
    }
}
