// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LegacyCommon",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "LegacyCommon",
            targets: ["LegacyCommon"]
        ),
        /*
         Future: When SPM decides to be a mature software product, move the Mocks here.
         macOS unit tests refused to link this target, even though every other target
         was fine with it:
        .library(
            name: "LegacyCommonTestSupport",
            targets: ["LegacyCommonTestSupport"]
        ),
         Notes:
          - You may encounter additional problems linking TrustKit (Undefined symbols
            ___llvm_profile_runtime)
          - Moving @Dependency based mocks to a separate module means each of these dependencies
            will have to be overridden in every test where its used (you cannot provide testValue
            in a separate module)
        */
    ],
    dependencies: [
        // External packages regularly upstreamed by our project (imported as submodules)
        .package(path: "../../external/protoncore"),

        // Local packages
        .package(path: "../Foundations/Domain"),
        .package(path: "../Foundations/Ergonomics"),
        .package(path: "../Foundations/LocalFeatureFlags"),
        .package(path: "../Foundations/PMLogger"),
        .package(path: "../Foundations/Strings"),
        .package(path: "../Foundations/Theme"),
        .package(path: "../Foundations/Timer"),

        .package(path: "../Shared/CommonNetworking"),
        .package(path: "../Shared/ExtensionIPC"),
        .package(path: "../Shared/Localization"),
        .package(path: "../Shared/Persistence"),

        .package(path: "../BugReport"),
        .package(path: "../Modals"),
        .package(path: "../NetShield"),
        .package(path: "../NEHelper"),
        .package(path: "../Settings"),

        // External dependencies
        .github("ashleymills", repo: "Reachability.swift", exact: "5.1.0"),
        .github("kishikawakatsumi", repo: "KeychainAccess", exact: "4.2.2"),
        .github("pointfreeco", repo: "swift-clocks", .upToNextMajor(from: "1.0.5")),
        .github("pointfreeco", repo: "swift-composable-architecture", .upToNextMajor(from: "1.15.1")),
        .github("pointfreeco", repo: "swift-dependencies", exact: "1.4.1"),
        .github("SDWebImage", repo: "SDWebImage", .upTo("5.16.0")),
        .github("ProtonMail", repo: "TrustKit", revision: "d107d7cc825f38ae2d6dc7c54af71d58145c3506"),
        .github("almazrafi", repo: "DictionaryCoder", exact: "1.1.0"),
//        .github("realm", repo: "SwiftLint", exact: "0.52.4"),
    ],
    targets: [
        .target(
            name: "LegacyCommon",
            dependencies: [
                // Local
                "Domain",
                "Ergonomics",
                "LocalFeatureFlags",
                "PMLogger",
                "Strings",
                "Theme",
                "Timer",
                .product(name: "Persistence", package: "Persistence"),
                "Localization",

                "ExtensionIPC",
                "CommonNetworking",
                .product(name: "VPNShared", package: "NEHelper"),
                .product(name: "VPNAppCore", package: "NEHelper"),
                .product(name: "VPNCrypto", package: "NEHelper"),

                "NetShield",
                "Modals",
                "Settings",
                "BugReport",

                // Todo: move these to LegacyCommonTestSupport, if we ever can
                .product(name: "CommonNetworkingTestSupport", package: "CommonNetworking"),
                .product(name: "VPNSharedTesting", package: "NEHelper"),
                .product(name: "TimerMock", package: "Timer"),

                // Core code
                .core(module: "AccountDeletion"),
                .core(module: "APIClient"),
                .core(module: "Authentication"),
                .core(module: "Challenge"),
                .core(module: "DataModel"),
                .core(module: "Doh"),
                .core(module: "Environment"),
                .core(module: "FeatureFlags"),
                .core(module: "ForceUpgrade"),
                .core(module: "Foundations"),
                .product(name: "GoLibsCryptoVPNPatchedGo", package: "protoncore"),
                .core(module: "HumanVerification"),
                .core(module: "Log"),
                .core(module: "Login"),
                .core(module: "Networking"),
                .core(module: "Payments"),
                .core(module: "PushNotifications"),
                .core(module: "Services"),
                .core(module: "UIFoundations"),
                .core(module: "Utilities"),
                .core(module: "Telemetry"),

                // External
                .product(name: "Clocks", package: "swift-clocks"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Reachability", package: "Reachability.swift"),
                .product(name: "SDWebImage", package: "SDWebImage"),
                .product(name: "TrustKit", package: "TrustKit"),
                .product(name: "DictionaryCoder", package: "DictionaryCoder")
            ],
            plugins: [
//                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
        /*
        .target(
            name: "LegacyCommonTestSupport",
            dependencies: [
                "LegacyCommon",
                "Strings",
                "Home",
                .product(name: "CommonNetworkingTestSupport", package: "CommonNetworking"),
                .product(name: "TimerMock", package: "Timer"),
                .product(name: "VPNAppCore", package: "NEHelper"),
                .product(name: "VPNShared", package: "NEHelper"),
                .product(name: "VPNSharedTesting", package: "NEHelper"),
                .product(name: "GoLibsCryptoVPNPatchedGo", package: "protoncore"),

                .core(module: "Authentication"),
                .core(module: "DataModel"),
                .core(module: "Foundations"),
                .core(module: "Networking"),
                .core(module: "Services"),
            ]
        ),
        */
        .testTarget(
            name: "LegacyCommonTests",
            dependencies: [
                "LegacyCommon",
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "PersistenceTestSupport", package: "Persistence"),
                .product(name: "TimerMock", package: "Timer"),
                .product(name: "VPNShared", package: "NEHelper"),
                .product(name: "VPNAppCore", package: "NEHelper"),
                .core(module: "TestingToolkitUnitTestsCore"),
                .core(module: "TestingToolkitUnitTestsFeatureFlag")
            ],
            resources: [
                .copy("Resources/test_log_1.log"),
                .copy("Resources/test_log_2.log"),
            ]
        ),
    ]
)

extension Range<PackageDescription.Version> {
    static func upTo(_ version: Version) -> Self {
        "0.0.0"..<version
    }
}

extension String {
    static func githubUrl(_ author: String, _ repo: String) -> Self {
        "https://github.com/\(author)/\(repo)"
    }
}

extension PackageDescription.Package.Dependency {
    static func github(_ author: String, repo: String, exact version: Version) -> Package.Dependency {
        .package(url: .githubUrl(author, repo), exact: version)
    }

    static func github(_ author: String, repo: String, revision: String) -> Package.Dependency {
        .package(url: .githubUrl(author, repo), revision: revision)
    }

    static func github(_ author: String, repo: String, _ range: Range<Version>) -> Package.Dependency {
        .package(url: .githubUrl(author, repo), range)
    }
}

extension PackageDescription.Target.Dependency {
    static func core(module: String) -> Self {
        .product(name: "ProtonCore\(module)", package: "protoncore")
    }
}
