import Foundation

/// 라이딩 데이터 DTO
public struct RideData: Identifiable, Codable {
    public let id: UUID
    public let startDate: Date
    
    public init(id: UUID, startDate: Date) {
        self.id = id
        self.startDate = startDate
    }
}
