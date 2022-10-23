// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "DescopeKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "DescopeKit",
            targets: ["DescopeKit"]),
    ],
    targets: [
        .target(
            name: "DescopeKit",
            path: "src"),
        .testTarget(
            name: "DescopeKitTests",
            dependencies: ["DescopeKit"],
            path: "test"),
    ]
)
