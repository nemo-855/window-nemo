// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "WindowNemo",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .executable(
            name: "WindowNemo",
            targets: ["WindowNemo"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WindowNemo",
            dependencies: []
        )
    ]
)