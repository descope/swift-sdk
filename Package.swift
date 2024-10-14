// swift-tools-version: 6.0
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
            path: "src",
            exclude: ["sdk/Callbacks.stencil"]),
        .testTarget(
            name: "DescopeKitTests",
            dependencies: ["DescopeKit"],
            path: "test"),
    ]
)
