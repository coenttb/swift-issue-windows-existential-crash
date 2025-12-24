/// Minimal reproduction case for Swift compiler crash on Windows
/// when mangling existential type for debug info.
///
/// The crash occurs during IRGen when the compiler attempts to mangle
/// `any Protocol` for DWARF debug information.

// MARK: - Rendering Protocol (matches swift-renderable pattern)

public enum Rendering {}

extension Rendering {
    /// A protocol for types that can be rendered to a buffer.
    public protocol `Protocol` {
        /// The type of content that this rendering type contains.
        associatedtype Content

        /// The context type used during rendering.
        associatedtype Context

        /// The output element type for the rendering buffer.
        associatedtype Output

        /// The body of this rendering type.
        var body: Content { get }

        /// Renders this type into the provided buffer.
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

/// Typealias for ergonomic conformance declarations.
public typealias Renderable = Rendering.`Protocol`

// MARK: - AnyRenderable (type-erased wrapper)

extension Rendering {
    public struct AnyView<Context, Bytes>: @unchecked Sendable
    where Bytes: RangeReplaceableCollection, Bytes.Element == UInt8 {
        /// The type-erased base content.
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

// MARK: - HTML Namespace (matches swift-html-rendering pattern)

public enum HTML {}

extension HTML {
    public struct Context {
        public init() {}
    }
}

extension HTML {
    /// A protocol representing an HTML element or component that can be rendered.
    /// This mirrors the real HTML.View protocol structure with constrained associated types.
    public protocol View: Renderable
    where Content: HTML.View, Context == HTML.Context, Output == UInt8 {
        @HTML.Builder var body: Content { get }
    }
}

extension HTML.View {
    @inlinable
    @_disfavoredOverload
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ html: Self,
        into buffer: inout Buffer,
        context: inout HTML.Context
    ) where Buffer.Element == UInt8 {
        Content._render(html.body, into: &buffer, context: &context)
    }
}

// MARK: - Never conformance

extension Never: HTML.View {
    public var body: Never { fatalError() }
}

// MARK: - HTML Builder

extension HTML {
    @resultBuilder
    public struct Builder {
        public static func buildBlock<Content: HTML.View>(_ content: Content) -> Content {
            content
        }
    }
}

// MARK: - HTML.AnyView (THIS TRIGGERS THE CRASH)

extension HTML {
    /// Type-erased wrapper for any HTML content.
    public struct AnyView: HTML.View, @unchecked Sendable {
        /// The existential type that causes the crash during debug info mangling on Windows
        public let base: any HTML.View

        private let renderFunction: (inout ContiguousArray<UInt8>, inout HTML.Context) -> Void

        public init<T: HTML.View>(_ base: T) {
            self.base = base
            self.renderFunction = { buffer, context in
                T._render(base, into: &buffer, context: &context)
            }
        }

        /// This initializer triggers the crash on Windows.
        /// The crash occurs when mangling `any HTML.View` for debug info.
        public init(_ base: any HTML.View) {
            if let anyView = base as? HTML.AnyView {
                self = anyView
            } else {
                self.base = base
                self.renderFunction = { buffer, context in
                    func render<T: HTML.View>(_ html: T) {
                        T._render(html, into: &buffer, context: &context)
                    }
                    render(base)
                }
            }
        }

        public static func _render<Buffer: RangeReplaceableCollection>(
            _ html: HTML.AnyView,
            into buffer: inout Buffer,
            context: inout HTML.Context
        ) where Buffer.Element == UInt8 {
            var contiguousBuffer = ContiguousArray<UInt8>()
            html.renderFunction(&contiguousBuffer, &context)
            buffer.append(contentsOf: contiguousBuffer)
        }

        public var body: Never { fatalError("body should not be called") }
    }
}

// MARK: - AnyRenderable conformance (retroactive-style)

extension AnyRenderable: Renderable where Context == HTML.Context {
    public typealias Content = Never
    public typealias Output = UInt8

    public var body: Never { fatalError("body should not be called") }
}

extension AnyRenderable: HTML.View where Context == HTML.Context {}

public typealias AnyHTML = HTML.AnyView
