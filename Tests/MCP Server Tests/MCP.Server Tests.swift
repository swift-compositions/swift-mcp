import JSON
import MCP_Server
import Testing

@Suite
struct `MCP.Server Tests` {

    static let server = MCP.Server(
        name: "test",
        version: "1.0.0",
        instructions: "Be kind.",
        tools: [
            MCP.Server.Tool(
                name: "echo",
                description: "Echoes.",
                input: .object([("type", "object")]),
                isReadOnly: true
            ) { arguments in
                MCP.Tool.Call.Result(value: .object([("said", arguments["text"])]))
            },
            MCP.Server.Tool(
                name: "fail",
                description: "Fails.",
                input: .object([("type", "object")]),
                isReadOnly: true
            ) { _ in
                .failure("no")
            },
        ]
    )

    static func respond(_ line: String) async throws -> JSON {
        let response = try #require(await server.respond(to: line))
        #expect(!response.contains("\n"), "stdio messages must be one line")
        return try JSON.parse(response)
    }

    @Test
    func `initialize agrees on a supported version and names the server`() async throws {
        let response = try await Self.respond(
            #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}"#
        )
        #expect(Int(response.id) == 1)
        #expect(String(response.result.protocolVersion) == "2025-06-18")
        #expect(String(response.result.serverInfo.name) == "test")
        #expect(String(response.result.instructions) == "Be kind.")
        #expect(response.result.capabilities.tools.isObject)
    }

    @Test
    func `an unknown version gets the newest one`() async throws {
        let response = try await Self.respond(
            #"{"jsonrpc":"2.0","id":"x","method":"initialize","params":{"protocolVersion":"1999-01-01"}}"#
        )
        #expect(String(response.id) == "x")
        #expect(String(response.result.protocolVersion) == MCP.Version.all[0].rawValue)
    }

    @Test
    func `tools are listed with their schema and read-only annotation`() async throws {
        let response = try await Self.respond(#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#)
        let tools = try #require(response.result.tools.array)
        #expect(tools.map { String($0.name) } == ["echo", "fail"])
        #expect(Bool(tools[0].annotations.readOnlyHint) == true)
        #expect(Bool(tools[0].annotations.destructiveHint) == false)
        #expect(String(tools[0].inputSchema.type) == "object")
    }

    @Test
    func `a tool call returns structured content and its text`() async throws {
        let response = try await Self.respond(
            #"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"echo","arguments":{"text":"hi"}}}"#
        )
        #expect(String(response.result.structuredContent.said) == "hi")
        #expect(String(response.result.content[0].type) == "text")
        #expect(
            try JSON.parse(String(response.result.content[0].text))
                == response.result.structuredContent
        )
        #expect(Bool(response.result.isError) == false)
    }

    @Test
    func `a failing tool reports a tool error, not a protocol error`() async throws {
        let response = try await Self.respond(
            #"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"fail"}}"#
        )
        #expect(Bool(response.result.isError) == true)
        #expect(String(response.result.structuredContent.error) == "no")
    }

    @Test(arguments: [
        (#"{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"nope"}}"#, -32602),
        (#"{"jsonrpc":"2.0","id":6,"method":"resources/list"}"#, -32601),
        (#"{"jsonrpc":"2.0","id":7,"#, -32700),
        (#"[1,2]"#, -32600),
    ])
    func `protocol errors carry JSON-RPC codes`(line: String, code: Int) async throws {
        let response = try await Self.respond(line)
        #expect(Int(response.error.code) == code)
    }

    @Test
    func `notifications get no answer`() async {
        #expect(
            await Self.server.respond(
                to: #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#
            ) == nil
        )
    }

    @Test
    func `responses to requests the server never sent get no answer`() async {
        #expect(await Self.server.respond(to: #"{"jsonrpc":"2.0","id":9,"result":{}}"#) == nil)
    }

    @Test
    func `a null id is a request, not a notification`() async throws {
        let response = try await Self.respond(#"{"jsonrpc":"2.0","id":null,"method":"ping"}"#)
        #expect(response.id.isNull)
        #expect(response.result.isObject)
    }

    @Test
    func `ping answers with an empty result`() async throws {
        let response = try await Self.respond(#"{"jsonrpc":"2.0","id":8,"method":"ping"}"#)
        #expect(response.result.object?.isEmpty == true)
    }
}
