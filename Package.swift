// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ExistentialCrash",
    products: [
        .library(name: "ExistentialCrash", targets: ["ExistentialCrash"]),
    ],
    dependencies: [
        // Base module in a SEPARATE PACKAGE - this is required to trigger the bug
        .package(url: "https://github.com/coenttb/swift-issue-windows-existential-crash-other-package", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "ExistentialCrash",
            dependencies: [
                .product(name: "BaseModule", package: "swift-issue-windows-existential-crash-other-package"),
            ]
        )
    ]
)
