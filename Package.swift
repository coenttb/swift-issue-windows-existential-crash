// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ExistentialCrash",
    products: [
        .library(name: "ExistentialCrash", targets: ["ExistentialCrash"]),
    ],
    dependencies: [
        // External dependency to match real scenario
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.2"),
    ],
    targets: [
        // Base module: defines the HTML namespace and base types
        .target(
            name: "BaseModule",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),

        // Rendering module: extends with View protocol and AnyView
        .target(
            name: "ExistentialCrash",
            dependencies: ["BaseModule"]
        )
    ],
    swiftLanguageModes: [.v6]
)

// Add Swift settings matching the real packages
for target in package.targets {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
