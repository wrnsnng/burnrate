// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Burnrate",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1")
    ],
    targets: [
        .executableTarget(
            name: "Burnrate",
            dependencies: ["Sparkle"],
            path: "Sources/Burnrate"
        )
    ]
)
