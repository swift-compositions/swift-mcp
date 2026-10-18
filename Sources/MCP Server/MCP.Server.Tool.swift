public import JSON
public import Model_Context_Protocol
import RFC_8259

extension MCP.Server {
    public struct Tool: Sendable {
        public var definition: MCP.Tool
        public var call: @Sendable (JSON) async -> MCP.Tool.Call.Result

        public init(
            definition: MCP.Tool,
            call: @escaping @Sendable (JSON) async -> MCP.Tool.Call.Result
        ) {
            self.definition = definition
            self.call = call
        }
    }
}

extension MCP.Server.Tool {
    public init(
        name: String,
        description: String,
        input: JSON,
        isReadOnly: Bool,
        call: @escaping @Sendable (JSON) async -> MCP.Tool.Call.Result
    ) {
        let annotations = MCP.Tool.Annotations(
            readOnlyHint: isReadOnly,
            destructiveHint: false,
            openWorldHint: false
        )
        self.init(
            definition: MCP.Tool(
                name: name,
                description: description,
                inputSchema: RFC_8259.Value(input),
                annotations: annotations
            ),
            call: call
        )
    }
}
