// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Burnrate",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Burnrate",
            path: "Sources/Burnrate"
        )
    ]
)
