// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AthanAlarm2",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "AthanCore",
            targets: ["AthanCore"]
        )
    ],
    targets: [
        .target(
            name: "AthanCore",
            path: "Sources/AthanCore"
        ),
        .testTarget(
            name: "AthanCoreTests",
            dependencies: ["AthanCore"],
            path: "Tests/AthanCoreTests"
        )
    ]
)
