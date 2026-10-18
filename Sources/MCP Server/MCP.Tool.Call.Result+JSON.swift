public import JSON
public import Model_Context_Protocol
import RFC_8259

extension MCP.Tool.Call.Result {
    public init(value: JSON, isError: Bool = false) {
        self.init(
            content: [.text(value.serialize())],
            structuredContent: RFC_8259.Value(value),
            isError: isError
        )
    }

    public static func failure(_ message: String) -> MCP.Tool.Call.Result {
        MCP.Tool.Call.Result(value: .object([("error", .string(message))]), isError: true)
    }
}
