// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Cloak",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Cloak",
            path: "Sources/Cloak"
        ),
    ]
)
