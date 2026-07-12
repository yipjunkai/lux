// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lux",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Lux", targets: ["Lux"])
    ],
    targets: [
        .executableTarget(
            name: "Lux",
            path: "Sources/Lux",
            swiftSettings: [
                // Start in Swift 5 mode; the DDC/IOKit layer fights Swift 6 strict
                // concurrency. We can graduate to .v6 once the hardware layer is stable.
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "LuxTests",
            dependencies: ["Lux"],
            path: "Tests/LuxTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
