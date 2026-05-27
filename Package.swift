// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "LucyTTS",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LucyTTS", targets: ["LucyTTS"])
    ],
    targets: [
        .executableTarget(
            name: "LucyTTS",
            path: "Sources/LucyTTS"
        ),
        .testTarget(
            name: "LucyTTSTests",
            dependencies: ["LucyTTS"],
            path: "Tests/LucyTTSTests"
        )
    ]
)
