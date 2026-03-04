import ProjectDescription

public enum BuildSettings {
    public static let bundleIdPrefix = "com.woong.MotoTrace"
    public static let deploymentTargets: DeploymentTargets = .iOS("18.0")
    public static let destinations: Destinations = [.iPhone]
}
