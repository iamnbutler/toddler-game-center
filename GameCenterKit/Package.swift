// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GameCenterKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "GameCenterKit", targets: ["GameCenterKit"]),
    ],
    targets: [
        .target(name: "GameCenterKit"),
        .testTarget(name: "GameCenterKitTests", dependencies: ["GameCenterKit"]),
    ]
)
