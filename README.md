# swift-mcp

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-compositions/swift-mcp/workflows/CI/badge.svg)](https://github.com/swift-compositions/swift-mcp/actions/workflows/ci.yml)

A tools-only Model Context Protocol server for Swift.

## Overview

`MCP.Server` answers one JSON-RPC message at a time, as the MCP stdio transport carries them: `initialize` (agreeing on a revision), `ping`, `tools/list` and `tools/call`. Notifications and responses get no answer. Each `MCP.Server.Tool` pairs an `MCP.Tool` definition with the code that runs it; a failing tool returns `MCP.Tool.Call.Result.failure(_:)`, which the model sees as a tool error rather than a protocol error.

The message types come from [swift-model-context-protocol](https://github.com/swift-linux-foundation/swift-model-context-protocol) and [swift-json-rpc-standard](https://github.com/swift-standards/swift-json-rpc-standard), both re-exported. JSON text is read and written with [swift-json](https://github.com/swift-compositions/swift-json).

## Products

- `MCP Server` (module `MCP_Server`).

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-compositions/swift-mcp.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "MCP Server", package: "swift-mcp"),
    ]
)
```

## Quick Start

```swift
import JSON
import MCP_Server

let server = MCP.Server(
    name: "echo",
    version: "1.0.0",
    tools: [
        MCP.Server.Tool(name: "echo", description: "Echoes its text.", input: .object([("type", "object")]), isReadOnly: true) { arguments in
            MCP.Tool.Call.Result(value: .object([("said", arguments["text"])]))
        },
    ]
)

while let line = readLine() {
    if let response = await server.respond(to: line) { print(response) }
}
```

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
