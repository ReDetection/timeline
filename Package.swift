// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var products: [Product] = []
var targets: [Target] = [
    .target(
        name: "TimelineCore",
        dependencies: [],
        path: "TimelineCore/",
        sources: [
            "Alerts.swift",
            "Logic/FilteredAppsStorage.swift",
            "Logic/PureAlignedTimer.swift",
            "Logic/PureCounter.swift",
            "Logic/Tracker.swift",
            "Storage/Model.swift",
            "Storage/Storage.swift"
        ]),
    .target(
        name: "testing_utils",
        dependencies: ["TimelineCore"],
        path: "testing-utils/"),
    .testTarget(
        name: "TimelineCoreTests",
        dependencies: ["TimelineCore", "testing_utils"],
        path: "TimelineCoreTests/"),
]

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/stephencelis/CSQLite.git", from: "0.0.3"),
    .package(url: "https://github.com/stephencelis/SQLite.swift.git", "0.13.3"..<"0.14.0"),
]

targets.append(
    .target(
        name: "SQLiteStorage",
        dependencies: [
            "TimelineCore",
            .product(name: "SQLite", package: "SQLite.swift"),
            .product(name: "CSQLite", package: "CSQLite"),
        ],
        path: "SQLiteStorage/")
)

#if os(macOS)
products.append(.executable(name: "Timeline-macOS", targets: ["TimelineCocoa"]))
targets.append(
    .executableTarget(
        name: "TimelineCocoa",
        dependencies: ["TimelineCore", "SQLiteStorage"],
        path: "macOS/",
        sources: [
            "AppDelegate.swift",
            "CocoaApps.swift",
            "CocoaTime.swift",
            "Date+Extensions.swift",
            "main.swift",
            "StatisticsView.swift",
            "CocoaAlerter.swift"
        ],
        resources: [
            .copy("macOS.entitlements"),
            .copy("timeline--macOS--Info.plist"),
        ])
)
#endif

#if os(Linux)
dependencies.append(.package(url: "https://github.com/aestesis/X11.git", branch: "master"))
products.append(.executable(name: "Timeline-linux", targets: ["TimelineLinux"]))
targets.append(
    .executableTarget(
        name: "TimelineLinux",
        dependencies: ["TimelineCore", "SQLiteStorage", "X11"],
        path: "linux/",
        sources: [
            "main.swift",
            "X11Apps.swift",
            "LinuxAlerter.swift"
        ])
)
#endif

let package = Package(
    name: "timeline",
    platforms: [
        .macOS(.v12)
    ],
    products: products,
    dependencies: dependencies,
    targets: targets
)
