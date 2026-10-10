// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "InterviewOSDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "InterviewOSDomain",
            targets: ["InterviewOSDomain"]
        )
    ],
    targets: [
        .target(
            name: "InterviewOSDomain"
        )
    ]
)
