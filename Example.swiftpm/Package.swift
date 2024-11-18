// swift-tools-version: 6.0

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Example",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Example",
            targets: ["AppModule"],
            bundleIdentifier: "dev.noppe.Example",
            teamIdentifier: "FBQ6Z8AF3U",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .plane),
            accentColor: .presetColor(.teal),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "CollectionViewDistributionalLayout", package: "collectionviewdistributionallayout")
            ],
            path: "."
        )
    ],
    swiftLanguageVersions: [.version("6")]
)