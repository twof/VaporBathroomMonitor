// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "BathroomMonitor",
    dependencies: [
        // 💧 A server-side Swift web framework. 
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc.1.1"),
        .package(url: "https://github.com/vapor/fluent-mysql", from: "3.0.0-rc.1")
    ],
    targets: [
        .target(name: "App", dependencies: [
            "Vapor",
            "FluentMySQL"
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

