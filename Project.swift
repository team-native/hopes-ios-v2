import ProjectDescription

let project = Project(
    name: "Hopes",
    targets: [
        .target(
            name: "Hopes",
            destinations: .iOS,
            product: .app,
            bundleId: "kr.hs.gsm.hopes",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Hopes",
                    "CFBundleShortVersionString": "2.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchScreen": [:]
                ]
            ),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            dependencies: [],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                    "SWIFT_VERSION": "5.0"
                ]
            )
        )
    ]
)
