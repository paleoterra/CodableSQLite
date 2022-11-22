// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodableSQLite",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CodableSQLite",
            targets: ["CodableSQLite"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CodableSQLite",
            dependencies: []),
        .testTarget(
            name: "CodableSQLiteTests",
            dependencies: ["CodableSQLite"])
    ]
)
