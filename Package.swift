// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SafeCoreData",
    platforms: [
        .iOS(.v10), .macOS(.v10_11)
    ],
    products: [
        .library(name: "SafeCoreData", targets: ["SafeCoreData"])
    ],
    targets: [
        .target(name: "SafeCoreData", path: "Sources/SafeCoreData")
    ]
)
