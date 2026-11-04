# swift-mcp

Use this package when you want to expose tools to a model through a Model Context Protocol server over stdio. Start from `MCP.Server` with a list of `MCP.Server.Tool` values, and feed each line you read to `MCP.Server.respond(to:)`. Reading and writing the stream is left to you. If you only need the protocol's message types, use swift-model-context-protocol, and for JSON-RPC alone, swift-json-rpc-standard.

## Laws

- `MCP.Server.respond(to:)` takes one message and returns one line of JSON with no newline in it, or nil when no answer is due. Notifications, and responses to requests the server never sent, get nil. A message whose id is null is a request and is answered.
- The server answers `initialize`, `ping`, `tools/list` and `tools/call`, and advertises only the tools capability. Any other method is answered with method not found (-32601).
- On `initialize` the server agrees to the client's protocol version if it is one of its `versions`, and otherwise offers the first of them, which by default is the newest.
- Text that isn't JSON gets a parse error (-32700) with a null id. JSON that isn't a request object, such as a batch array, gets an invalid request error (-32600). A call to a tool that doesn't exist gets invalid params (-32602).
- Tools are found by name, and the first with that name wins. A tool that fails returns `MCP.Tool.Call.Result.failure(_:)`, which reaches the model as a tool result marked as an error, not as a protocol error.
- A tool result built from JSON carries the value twice: as structured content, and as its serialized text in a single text block.
- A tool made with `MCP.Server.Tool.init(name:description:input:isReadOnly:call:)` is always marked as neither destructive nor open world.
