// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ExistentialCrash",
    products: [
        .library(name: "ExistentialCrash", targets: ["ExistentialCrash"]),
    ],
    targets: [
        // Base module: defines the HTML namespace and base types
        .target(name: "BaseModule"),

        // Rendering module: extends with View protocol and AnyView
        .target(
            name: "ExistentialCrash",
            dependencies: ["BaseModule"]
        )
    ]
)
