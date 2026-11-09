import Foundation

public enum SettingsIntent {
    case load
    case observeAuthorization
    /// 급가속·급감속은 한 슬라이더로 함께 조정한다
    case changeAccelerationThreshold(Double)
    case changeLeanAngleThreshold(Double)
    case changeStopSpeedThreshold(Double)
    /// 슬라이더 조작이 끝난 시점에 저장한다
    case commitChanges
    case resetToDefaults
}
