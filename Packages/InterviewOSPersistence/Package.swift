// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "InterviewOSPersistence",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "InterviewOSPersistence",
            targets: ["InterviewOSPersistence"]
        )
    ],
    dependencies: [
        .package(path: "../InterviewOSDomain")
    ],
    targets: [
        .target(
            name: "InterviewOSPersistence",
            dependencies: [
                .product(name: "InterviewOSDomain", package: "InterviewOSDomain")
            ]
        )
    ]
)
