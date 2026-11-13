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
                    "UILaunchScreen": [:],
                    "NSCameraUsageDescription": "질문에 첨부할 사진을 촬영하기 위해 카메라 접근이 필요합니다.",
                    "NSPhotoLibraryUsageDescription": "질문에 첨부할 사진을 선택하기 위해 사진 보관함 접근이 필요합니다."
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
