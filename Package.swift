// swift-tools-version: 6.0
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
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "CollectionViewDistributionalLayout",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "CollectionViewDistributionalLayoutTests",
            dependencies: ["CollectionViewDistributionalLayout"]
        ),
    ]
)
