import Foundation
import CoreLocation  // Apple의 CoreLocation 프레임워크 사용

/// 위치 추적 서비스 프로토콜
public protocol TrackingServiceInterface {
    // 위치 추적 메서드
}

/// 추적 데이터 DTO
public struct TrackingData: Codable {
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    
    public init(latitude: Double, longitude: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}
