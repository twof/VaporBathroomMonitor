// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "BathroomMonitor",
    dependencies: [
        // 💧 A server-side Swift web framework. 
        .package(url: "https://github.com/vapor/vapor.git", .branch("beta")),
        .package(url: "https://github.com/sandordobi/fluent-mysql", "3.0.0-beta.3"..<"3.0.0-beta.4"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            "Vapor",
            "FluentMySQL",
            "FluentSQLite"
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

