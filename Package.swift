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
            url: "https://github.com/pis123/SunellSDK/releases/download/1.1.1/SunellSDK.xcframework.zip",
            checksum: "e34e668db0f00b0ae138a9e6ed090587171e5060e8c8a9b548d804060d474222"
        )
    ]
)
