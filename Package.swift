// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GameTemplate",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "GameTemplate", targets: ["GameTemplate"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GameTemplate",
            path: "Sources/GameTemplate",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "GameTemplateTests",
            dependencies: ["GameTemplate"],
            path: "Tests/GameTemplateTests"
        )
    ]
)
