import CoreTrackingInterface

public enum TrackingAnalyzerFactory {
    public static func create(
        thresholds: TrackingThresholds = TrackingThresholds(
            accelerationKmhPerSec: 16.7,
            decelerationKmhPerSec: 16.7,
            minLeanAngleDegrees: 30.0,
            stopSpeedKmh: 1.0
        )
    ) -> TrackingAnalyzerInterface {
        return TrackingAnalyzer(thresholds: thresholds)
    }
}
