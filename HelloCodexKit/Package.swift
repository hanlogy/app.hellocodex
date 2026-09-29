// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HelloCodexKit",
    platforms: [.macOS(.v14)],
    // What the app target links; tests use the targets directly.
    products: [
        .library(name: "CodexClient", targets: ["CodexClient"]),
        .library(name: "Storage", targets: ["Storage"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "WeeklyLimit", targets: ["WeeklyLimit"]),
        .library(name: "WeeklyLimitUI", targets: ["WeeklyLimitUI"]),
    ],
    targets: [
        // Infrastructure: feature-neutral, depends on nothing.
        .target(name: "CodexClient"),
        .target(name: "Storage"),
        .target(name: "DesignSystem", resources: [.process("Colors.xcassets")]),

        // Features: built on the infrastructure, never on each other.
        .target(name: "WeeklyLimit", dependencies: ["CodexClient", "Storage"]),
        .target(name: "WeeklyLimitUI", dependencies: ["WeeklyLimit", "DesignSystem"]),

        .testTarget(name: "CodexClientTests", dependencies: ["CodexClient"]),
        .testTarget(name: "StorageTests", dependencies: ["Storage"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .testTarget(name: "WeeklyLimitTests", dependencies: ["WeeklyLimit"]),
        .testTarget(name: "WeeklyLimitUITests", dependencies: ["WeeklyLimitUI"]),
    ]
)
