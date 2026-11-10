public import Model_Context_Protocol

extension MCP.Tool.Call.Result {
    public enum Layout: Sendable, Hashable {
        case compact
        case pretty
    }
}
