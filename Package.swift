// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-mcp",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "MCP Server",
            targets: ["MCP Server"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-compositions/swift-json.git", branch: "main"),
        .package(
            url: "https://github.com/swift-standards/swift-json-rpc-standard.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-linux-foundation/swift-model-context-protocol.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-ietf/swift-rfc-8259.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MCP Server",
            dependencies: [
                .product(name: "JSON", package: "swift-json"),
                .product(name: "JSON RPC Standard", package: "swift-json-rpc-standard"),
                .product(name: "Model Context Protocol", package: "swift-model-context-protocol"),
                .product(name: "RFC 8259", package: "swift-rfc-8259"),
            ]
        ),
        .testTarget(
            name: "MCP Server Tests",
            dependencies: [
                .target(name: "MCP Server"),
                .product(name: "JSON", package: "swift-json"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
