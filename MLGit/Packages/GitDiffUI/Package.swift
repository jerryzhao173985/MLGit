// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "GitDiffUI",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "GitDiffUI",
            targets: ["GitDiffUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.1.2")
    ],
    targets: [
        .target(
            name: "GitDiffUI",
            dependencies: ["Highlightr"],
            path: "Sources"
        ),
        .testTarget(
            name: "GitDiffUITests",
            dependencies: ["GitDiffUI"],
            path: "Tests"
        ),
    ]
)
