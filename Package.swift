// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "ExistentialCrash",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
    ],
    products: [
        .library(name: "ExistentialCrash", targets: ["ExistentialCrash"]),
    ],
    dependencies: [
        // This package contains HTML.AnyView which triggers the crash
        .package(url: "https://github.com/coenttb/swift-html-rendering", from: "0.1.15"),
    ],
    targets: [
        // Just import the library that contains the crashing code
        .target(
            name: "ExistentialCrash",
            dependencies: [
                .product(name: "HTML Renderable", package: "swift-html-rendering"),
            ]
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
