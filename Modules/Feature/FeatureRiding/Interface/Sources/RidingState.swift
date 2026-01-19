import Foundation

/// 라이딩 Feature의 State (MVI 패턴)
public struct RidingState {
    public var isRiding: Bool
    
    public init(isRiding: Bool = false) {
        self.isRiding = isRiding
    }
}
