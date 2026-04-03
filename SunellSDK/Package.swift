// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SunellSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SunellSDK",
            targets: ["SunellSDK"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "SunellSDK",
            url: "https://github.com/pis123/Sunell/releases/download/1.0.0/SunellSDK.xcframework.zip",
            checksum: "227078a562d8b0ad913d76ea3c009eba99c6a7dd0658a64cfd826d32215387d1"
        )
    ]
)
