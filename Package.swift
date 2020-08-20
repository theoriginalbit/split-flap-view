// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SplitflapView",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "SplitflapView", targets: ["SplitflapView"]),
    ],
    targets: [
        .target(name: "SplitflapView"),
    ]
)
