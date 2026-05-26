// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "LiveFishTTS",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LiveFishTTS", targets: ["LiveFishTTS"])
    ],
    targets: [
        .executableTarget(
            name: "LiveFishTTS",
            path: "Sources/LiveFishTTS"
        )
    ]
)
