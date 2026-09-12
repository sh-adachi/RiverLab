// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RiverLabCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "RiverLabCore", targets: ["RiverLabCore"])],
    targets: [
        .target(name: "RiverLabCore", path: "Core"),
        .testTarget(name: "RiverLabCoreTests", dependencies: ["RiverLabCore"], path: "Tests/RiverLabCoreTests")
    ]
)
