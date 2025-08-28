// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ABLEManager",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "ABLEManager", targets: ["ABLEManager"])
    ],
    targets: [
        .target(
            name: "ABLEManager",
            // This matches your CocoaPods `s.source_files = "ABLEManager/Sources/**/*.{swift}"`
            path: "ABLEManager/Sources"
        )
        // If you add tests later, declare a test target here.
    ]
)
