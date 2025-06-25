// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MLGit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MLGit",
            targets: ["MLGit"]),
    ],
    dependencies: [
        // Existing dependencies
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.3.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.8"),
        
        // New enhanced visualization dependencies
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.3.0"),
        .package(url: "https://github.com/simonbs/Runestone", from: "0.3.0"),
        .package(url: "https://github.com/guillermomuntaner/GitDiff", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MLGit",
            dependencies: [
                .product(name: "Highlightr", package: "Highlightr"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "Runestone", package: "Runestone"),
                .product(name: "GitDiff", package: "GitDiff"),
            ],
            path: "MLGit"
        ),
        .testTarget(
            name: "MLGitTests",
            dependencies: ["MLGit"],
            path: "MLGitTests"
        ),
    ]
)