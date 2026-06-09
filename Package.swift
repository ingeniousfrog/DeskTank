// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeskTank",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DeskTank", targets: ["DeskTank"]),
        .library(name: "DeskTankCore", targets: ["DeskTankCore"])
    ],
    targets: [
        .target(
            name: "DeskTankCore"
        ),
        .executableTarget(
            name: "DeskTank",
            dependencies: ["DeskTankCore"]
        ),
        .testTarget(
            name: "DeskTankCoreTests",
            dependencies: ["DeskTankCore"]
        )
    ]
)
