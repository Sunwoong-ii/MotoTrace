import CoreDataStorageInterface

/// 데이터 저장소 서비스 팩토리
public enum DataStorageServiceFactory {
    public static func create() -> DataStorageServiceInterface {
        return DataStorageService()
    }
}
