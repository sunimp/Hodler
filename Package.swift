// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "Hodler",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Hodler",
            targets: ["Hodler"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sunimp/BitcoinCore.Swift.git", .upToNextMajor(from: "3.0.2")),
        .package(url: "https://github.com/sunimp/WWCryptoKit.Swift.git", .upToNextMajor(from: "1.3.2")),
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
