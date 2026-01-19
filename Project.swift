import ProjectDescription

let project = Project(
    name: "MotoTrace",
    targets: [
        .target(
            name: "MotoTrace",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.MotoTrace",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "MotoTrace/Sources",
                "MotoTrace/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "MotoTraceTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.MotoTraceTests",
            infoPlist: .default,
            buildableFolders: [
                "MotoTrace/Tests"
            ],
            dependencies: [.target(name: "MotoTrace")]
        ),
    ]
)
