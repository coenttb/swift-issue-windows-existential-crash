// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ExistentialCrash",
    products: [
        .library(name: "ExistentialCrash", targets: ["ExistentialCrash"]),
    ],
    targets: [
        // Base module: defines the namespace (like WHATWG_HTML_Shared)
        .target(name: "BaseModule"),

        // Extension module: adds protocol to namespace (like HTML_Renderable)
        .target(
            name: "ExistentialCrash",
            dependencies: ["BaseModule"]
        )
    ]
)

// Match the Swift settings from the crashing packages
for target in package.targets {
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
    ]
}
