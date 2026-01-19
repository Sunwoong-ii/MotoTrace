import Foundation

/// 데이터 저장소 서비스 프로토콜
public protocol DataStorageServiceInterface {
    // 데이터 저장소 메서드
}

/// 라이딩 데이터 DTO
public struct RideData: Identifiable, Codable {
    public let id: UUID
    public let startDate: Date
    
    public init(id: UUID, startDate: Date) {
        self.id = id
        self.startDate = startDate
    }
}
