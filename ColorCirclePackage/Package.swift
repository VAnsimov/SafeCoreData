// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColorCirclePackage",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "ColorCirclePackage",
            targets: ["ColorCirclePackage"]),
    ],
    dependencies: [
        .package(url: "git@github.com:VAnsimov/SafeCoreData.git", .upToNextMajor(from: "0.1.0")),
        .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk.git", from: "8.2.0")
    ],
    targets: [
        .target(
            name: "ColorCirclePackage",
            dependencies: ["SafeCoreData",
                           .product(name: "FirebaseAuth", package: "Firebase")]),
        .testTarget(
            name: "ColorCirclePackageTests",
            dependencies: ["ColorCirclePackage"]),
    ]
)
