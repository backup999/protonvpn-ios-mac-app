// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Connection",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "CertificateAuthentication", targets: ["CertificateAuthentication"]),
        .library(name: "LocalAgent", targets: ["LocalAgent"]),
        .library(name: "Connection", targets: ["Connection"]),
        .library(name: "ConnectionFoundations", targets: ["ConnectionFoundations"]),
        .library(name: "ConnectionTestSupport", targets: ["ConnectionFoundationsTestSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "1.15.1")),
        .package(path: "../../../external/protoncore"), // GoLibs
        .package(path: "../../Foundations/Domain"),
        .package(path: "../../Foundations/Ergonomics"),
        .package(path: "../../Foundations/PMLogger"),
        .package(path: "../../Foundations/Strings"),
        .package(path: "../../Shared/ExtensionIPC"),
        .package(path: "../../NEHelper"),
    ],
    targets: [
        .target(
            name: "ConnectionFoundations",
            dependencies: [
                "Domain",
                "Ergonomics",
                "ExtensionIPC",
                "PMLogger",
                .product(name: "VPNShared", package: "NEHelper"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "CertificateAuthentication",
            dependencies: [
                "ConnectionFoundations",
                "ExtensionIPC",
                .product(name: "GoLibsCryptoVPNPatchedGo", package: "protoncore"),
                .product(name: "VPNAppCore", package: "NEHelper"), // VpnAuthKeychain
            ]
        ),
        .target(
            name: "LocalAgent",
            dependencies: [
                "ConnectionFoundations",
                .product(name: "GoLibsCryptoVPNPatchedGo", package: "protoncore"),
            ]
        ),
        .target(
            name: "ExtensionManager",
            dependencies: [
                "ConnectionFoundations",
                "Domain",
                "ExtensionIPC",
            ]
        ),
        .target(
            name: "Connection",
            dependencies: [
                "Strings",
                "CertificateAuthentication",
                "ExtensionManager",
                "LocalAgent",
            ]
        ),
        .target(name: "ConnectionFoundationsTestSupport", dependencies: ["ConnectionFoundations"]),
        .testTarget(
            name: "ConnectionTests",
            dependencies: [
                "Connection",
                "ConnectionFoundationsTestSupport",
                .product(name: "DomainTestSupport", package: "Domain"),
                .product(name: "VPNSharedTesting", package: "NEHelper"),
            ]
        ),
        .testTarget(
            name: "ExtensionManagerTests",
            dependencies: [
                "ExtensionManager",
                .product(name: "DomainTestSupport", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "CertificateAuthenticationTests",
            dependencies: [
                "CertificateAuthentication",
                "ConnectionFoundationsTestSupport",
                .product(name: "DomainTestSupport", package: "Domain"),
                .product(name: "VPNSharedTesting", package: "NEHelper"),
            ]
        ),
        .testTarget(
            name: "LocalAgentTests",
            dependencies: [
                "LocalAgent",
                .product(name: "DomainTestSupport", package: "Domain"),
            ]
        ),
    ]
)
