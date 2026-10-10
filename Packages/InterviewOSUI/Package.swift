// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "InterviewOSUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "InterviewOSUI",
            targets: ["InterviewOSUI"]
        )
    ],
    dependencies: [
        .package(path: "../InterviewOSDomain"),
        .package(path: "../InterviewOSPersistence")
    ],
    targets: [
        .target(
            name: "InterviewOSUI",
            dependencies: [
                .product(name: "InterviewOSDomain", package: "InterviewOSDomain"),
                .product(name: "InterviewOSPersistence", package: "InterviewOSPersistence")
            ]
        )
    ]
)
