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
                    "CFBundleDisplayName": "hopes",
                    "CFBundleShortVersionString": "2.0.0",
                    "CFBundleVersion": "1",
                    "UIAppFonts": ["Inter-Variable.ttf"],
                    "UILaunchScreen": [:],
                    "UIUserInterfaceStyle": "Light",
                    "HopesAPIBaseURL": "http://service.gsmsv.site:22116",
                    "NSAppTransportSecurity": [
                        "NSExceptionDomains": [
                            "service.gsmsv.site": [
                                "NSExceptionAllowsInsecureHTTPLoads": true,
                                "NSIncludesSubdomains": true
                            ]
                        ]
                    ],
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": false,
                        "UISceneConfigurations": [
                            "UIWindowSceneSessionRoleApplication": [[
                                "UISceneConfigurationName": "Default Configuration",
                                "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                            ]]
                        ]
                    ],
                    "NSCameraUsageDescription": "질문에 첨부할 사진을 촬영하기 위해 카메라 접근이 필요합니다.",
                    "NSPhotoLibraryUsageDescription": "질문에 첨부할 사진을 선택하기 위해 사진 보관함 접근이 필요합니다.",
                    "NSLocationWhenInUseUsageDescription": "학교 안 현재 위치를 알려주는 데 사용돼요."
                ]
            ),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            dependencies: [],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                    "SWIFT_VERSION": "5.0",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "XVUY3P7HN4",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "",
                    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": ""
                ]
            )
        ),
        .target(
            name: "HopesTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "kr.hs.gsm.hopes.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "Hopes")]
        )
    ]
)
