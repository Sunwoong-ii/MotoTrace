import CoreTrackingInterface

/// 위치 추적 서비스 팩토리
public enum TrackingServiceFactory {
    public static func create() -> TrackingServiceInterface {
        return TrackingService()
    }
}
