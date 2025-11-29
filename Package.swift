// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CollectionViewDistributionalLayout",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "CollectionViewDistributionalLayout",
            targets: ["CollectionViewDistributionalLayout"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CollectionViewDistributionalLayout",
            dependencies: []
        ),
        .testTarget(
            name: "CollectionViewDistributionalLayoutTests",
            dependencies: ["CollectionViewDistributionalLayout"]
        ),
    ]
)
