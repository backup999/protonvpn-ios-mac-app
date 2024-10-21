// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Persistence",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "PersistenceTestSupport", targets: ["PersistenceTestSupport"])
    ],
    dependencies: [
        .package(path: "../../Foundations/Domain"),
        .package(path: "../../Foundations/Ergonomics"),
        .package(path: "../../Foundations/PMLogger"),
        .package(url: "https://github.com/apple/swift-log.git", exact: "1.4.4"),
        .package(path: "../../Shared/Localization"), // LocaleWrapper is required for country code mappings
        .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.4.1"),
        .package(url: "https://github.com/groue/GRDB.swift", exact: "6.29.2"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", .upToNextMajor(from: "1.4.2")),
    ],
    targets: [
        .target(
            name: "Persistence",
            dependencies: [
                "Domain",
                "Ergonomics",
                "PMLogger",
                .product(name: "Logging", package: "swift-log"),
                "Localization",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
            ]
        ),
        .target(
            name: "PersistenceTestSupport",
            dependencies: [
                "Persistence",
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: [
                "Persistence",
                "PersistenceTestSupport",
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
            ],
            resources: [.process("Resources")]
        ),
    ]
)
