// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "GitHTMLParser",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "GitHTMLParser",
            targets: ["GitHTMLParser"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "GitHTMLParser",
            dependencies: ["SwiftSoup"],
            path: "Sources"
        ),
        .testTarget(
            name: "GitHTMLParserTests",
            dependencies: ["GitHTMLParser"],
            path: "Tests"
        ),
    ]
)
