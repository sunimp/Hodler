// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "Hodler",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Hodler",
            targets: ["Hodler"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sunimp/BitcoinCore.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.54.6"),
    ],
    targets: [
        .target(
            name: "Hodler",
            dependencies: [
                "BitcoinCore"
            ]
        ),
    ]
)
