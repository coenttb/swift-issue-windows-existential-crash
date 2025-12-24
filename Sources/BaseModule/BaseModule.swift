/// Base module that defines the HTML namespace.
/// This simulates WHATWG_HTML_Shared which defines the base namespace.

/// The namespace enum - defined here, extended in another module
public enum HTML {}

/// Context type used by the View protocol
extension HTML {
    public struct Context: Sendable {
        public init() {}
    }
}
