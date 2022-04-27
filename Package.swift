// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

func platformDependentTargets() -> [Target] {
#if os(macOS)
    return [
        .executableTarget(
            name: "Timeline",
            dependencies: ["TimelineCore", "SQLiteStorage"],
            path: "macOS/",
            resources: [
                .copy("macOS/macOS.entitlements"),
                .copy("macOS/timeline--macOS--Info.plist"),
            ]),
    ]
#else
    return [
        .executableTarget(
            name: "Timeline",
            dependencies: ["TimelineCore", "testing_utils"],
            path: "linux/")
    ]
#endif
}

let package = Package(
    name: "timeline",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "Timeline", targets: ["Timeline"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", "0.13.3"..<"0.14.0"),
    ],
    targets: [
        .target(
            name: "TimelineCore",
            dependencies: [],
            path: "TimelineCore/"),
        .target(
            name: "SQLiteStorage",
            dependencies: [
                "TimelineCore",
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            path: "SQLiteStorage/"),
        .target(
            name: "testing_utils",
            dependencies: ["TimelineCore"],
            path: "testing-utils/"),
        .testTarget(
            name: "TimelineCoreTests",
            dependencies: ["TimelineCore", "testing_utils"],
            path: "TimelineCoreTests/"),
    ] + platformDependentTargets()
)
