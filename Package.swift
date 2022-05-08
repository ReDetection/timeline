// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "timeline",
    platforms: [
        .macOS(.v12)
    ],
    products: [],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", "0.13.3"..<"0.14.0"),
        .package(url: "https://github.com/aestesis/X11.git", branch: "master"),
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
    ]
)

#if os(macOS)
// only brave use this, as SPM does not support macOS apps. Use xcodeproj instead
package.products += [.executable(name: "Timeline", targets: ["TimelineCocoa"])]
package.targets += [.executableTarget(
    name: "TimelineCocoa",
    dependencies: ["TimelineCore", "SQLiteStorage"],
    path: "macOS/",
    resources: [
        .copy("macOS/macOS.entitlements"),
        .copy("macOS/timeline--macOS--Info.plist"),
    ]),
]

#elseif os(Linux)
package.products.append(.executable(name: "Timeline", targets: ["Timeline"]))
package.targets.append(.executableTarget(
    name: "Timeline",
    dependencies: ["TimelineCore", "SQLiteStorage", "X11"],
    path: "linux/")
)
#endif

