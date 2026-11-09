import JSON
import JSON_RPC_Standard
public import Model_Context_Protocol
import RFC_8259

extension MCP {
    public struct Server: Sendable {
        public var info: MCP.Implementation
        public var instructions: String?
        public var tools: [MCP.Server.Tool]
        /// The protocol versions this server speaks, in any order. On `initialize` a client asking for another
        /// version gets the newest of these (MCP versions are `YYYY-MM-DD` dates, so the greatest is the newest);
        /// an empty list answers `initialize` with an internal error.
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

extension MCP.Server {
    public func respond(to line: String) async -> String? {
        let message: RFC_8259.Value
        do throws(RFC_8259.Error) {
            message = try JSON.Decode.parse(line)
        } catch {
            return Self.line(
                JSON_RPC.Response(
                    id: .null,
                    result: .failure(JSON_RPC.Error(code: .parseError, message: "Parse error"))
                )
            )
        }
        if message.object != nil, message["method"] == nil { return nil }
        let request: JSON_RPC.Request
        do throws(JSON_RPC.Error) {
            request = try JSON_RPC.Request(message)
        } catch {
            return Self.line(JSON_RPC.Response(id: .null, result: .failure(error)))
        }
        guard let id = request.id else { return nil }
        let result: Swift::Result<RFC_8259.Value, JSON_RPC.Error>
        do throws(JSON_RPC.Error) {
            result = .success(try await answer(request))
        } catch {
            result = .failure(error)
        }
        return Self.line(JSON_RPC.Response(id: id, result: result))
    }

    func answer(_ request: JSON_RPC.Request) async throws(JSON_RPC.Error) -> RFC_8259.Value {
        switch MCP.Method(rawValue: request.method) {
        case .initialize:
            let requested = try MCP.Initialize.Parameters(request.params).protocolVersion
            guard let newest = versions.max(by: { $0.rawValue < $1.rawValue }) else {
                throw JSON_RPC.Error(code: .internalError, message: "Server supports no protocol version")
            }
            return MCP.Initialize.Result(
                protocolVersion: versions.contains(requested) ? requested : newest,
                capabilities: MCP.Capabilities(tools: MCP.Capabilities.Tools()),
                serverInfo: info,
                instructions: instructions
            ).value
        case .ping:
            return .object(RFC_8259.Object())
        case .toolsList:
            return MCP.Tool.List.Result(tools: tools.map(\.definition)).value
        case .toolsCall:
            let call = try MCP.Tool.Call(request.params)
            guard let tool = tools.first(where: { $0.definition.name == call.name }) else {
                throw JSON_RPC.Error(code: .invalidParams, message: "Unknown tool: \(call.name)")
            }
            return await tool.call(JSON(.object(call.arguments))).value
        default:
            throw JSON_RPC.Error(code: .methodNotFound, message: "Method not found")
        }
    }

    static func line(_ response: JSON_RPC.Response) -> String {
        JSON(response.value).serialize()
    }
}
