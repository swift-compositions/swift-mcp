public import Model_Context_Protocol

extension MCP {
    public struct Server: Sendable {
        public var info: MCP.Implementation
        public var instructions: String?
        public var tools: [MCP.Server.Tool]
        public var versions: [MCP.Version]

        public init(
            info: MCP.Implementation,
            instructions: String? = nil,
            tools: [MCP.Server.Tool],
            versions: [MCP.Version] = MCP.Version.all
        ) {
            self.info = info
            self.instructions = instructions
            self.tools = tools
            self.versions = versions
        }
    }
}

extension MCP.Server {
    public init(
        name: String,
        // swift-linter:disable:next raw concept
        // REASON: MCP Implementation.version is a free string in the protocol (Version.Semantic and Version.Tools refuse what servers may send); MCP.Implementation holds it raw for the same reason.
        version: String,
        instructions: String? = nil,
        tools: [MCP.Server.Tool]
    ) {
        self.init(
            info: MCP.Implementation(name: name, version: version),
            instructions: instructions,
            tools: tools
        )
    }
}
