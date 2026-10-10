// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "InterviewOSApplePersistence",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "InterviewOSApplePersistence",
            targets: ["InterviewOSApplePersistence"]
        )
    ],
    dependencies: [
        .package(path: "../InterviewOSDomain"),
        .package(path: "../InterviewOSPersistence")
    ],
    targets: [
        .target(
            name: "InterviewOSApplePersistence",
            dependencies: [
                .product(name: "InterviewOSDomain", package: "InterviewOSDomain"),
                .product(name: "InterviewOSPersistence", package: "InterviewOSPersistence")
            ]
        )
    ]
)
