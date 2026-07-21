// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VLSKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "VLSKit", targets: ["VLSKit"]),
        .library(name: "VLSKitUI", targets: ["VLSKitUI"]),
    ],
    targets: [
        .target(
            name: "VLSKit",
            path: "Sources/VLSKit"
        ),
        .target(
            name: "VLSKitUI",
            dependencies: ["VLSKit"],
            path: "Sources/VLSKitUI"
        ),
        .testTarget(
            name: "VLSKitTests",
            dependencies: ["VLSKit"],
            path: "Tests/VLSKitTests"
        ),
    ]
)
