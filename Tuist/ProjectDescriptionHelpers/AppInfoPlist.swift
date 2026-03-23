//
//  AppInfoPlist.swift
//  ProjectDescriptionHelpers
//
//  Created by 웅 on 1/20/26.
//

import ProjectDescription

public enum AppInfoPlist {
    public static let base: [String: Plist.Value] = [
        "NSLocationWhenInUseUsageDescription": "사용자의 이동 경로와 뱅킹각을 측정하기 위해 위치 권한이 필요합니다.",
        "NSLocationAlwaysAndWhenInUseUsageDescription": "백그라운드에서도 끊김 없이 라이딩 기록을 측정하기 위해 위치 권한이 항상 필요합니다.",
        "NSLocationAlwaysUsageDescription": "백그라운드에서도 끊김 없이 라이딩 기록을 측정하기 위해 위치 권한이 항상 필요합니다.",
        "UIBackgroundModes": [
            "location"
        ],
        "UILaunchScreen": [
            "UIColorName": "LaunchBackgroundColor",
            "UIImageName": "LaunchLogo",
            "UIImageRespectsSafeAreaInsets": false
        ],
        "UILaunchStoryboardName": ""
    ]
}
