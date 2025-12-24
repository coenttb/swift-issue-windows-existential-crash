/// Base module that defines the HTML namespace and Rendering protocol.
/// This simulates WHATWG_HTML_Shared and Rendering modules.

// MARK: - Rendering Protocol

public enum Rendering {}

extension Rendering {
    public protocol `Protocol` {
        associatedtype Content
        associatedtype Context
        associatedtype Output
        var body: Content { get }

        static func _render<Buffer: RangeReplaceableCollection>(
            _ markup: Self,
            into buffer: inout Buffer,
            context: inout Context
        ) where Buffer.Element == Output
    }
}

extension Rendering.`Protocol`
where Content: Rendering.`Protocol`, Content.Context == Context, Content.Output == Output {
    @inlinable
    @_disfavoredOverload
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ markup: Self,
        into buffer: inout Buffer,
        context: inout Context
    ) where Buffer.Element == Output {
        Content._render(markup.body, into: &buffer, context: &context)
    }
}

public typealias Renderable = Rendering.`Protocol`

// MARK: - Rendering.AnyView

extension Rendering {
    public struct AnyView<Context, Bytes>: @unchecked Sendable
    where Bytes: RangeReplaceableCollection, Bytes.Element == UInt8 {
        public let base: any Rendering.`Protocol`

        private let renderFunction: (inout Bytes, inout Context) -> Void

        public init<T: Rendering.`Protocol`>(_ base: T)
        where T.Context == Context, T.Output == UInt8 {
            self.base = base
            self.renderFunction = { buffer, context in
                T._render(base, into: &buffer, context: &context)
            }
        }

        public func render(into buffer: inout Bytes, context: inout Context) {
            renderFunction(&buffer, &context)
        }
    }
}

public typealias AnyRenderable<Context, Bytes> = Rendering.AnyView<Context, Bytes>
where Bytes: RangeReplaceableCollection, Bytes.Element == UInt8

// MARK: - HTML Namespace (defined in base module, like WHATWG_HTML_Shared)

public enum HTML {}

extension HTML {
    public struct Context {
        public init() {}
    }
}
