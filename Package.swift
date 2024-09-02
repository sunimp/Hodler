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
            targets: ["Hodler"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sunimp/BitcoinCore.Swift.git", .upToNextMajor(from: "3.2.0")),
        .package(url: "https://github.com/sunimp/WWCryptoKit.Swift.git", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.54.3"),
    ],
    targets: [
        .target(
            name: "Hodler",
            dependencies: [
                .product(name: "BitcoinCore", package: "BitcoinCore.Swift"),
                .product(name: "WWCryptoKit", package: "WWCryptoKit.Swift"),
            ]
        ),
    ]
)
