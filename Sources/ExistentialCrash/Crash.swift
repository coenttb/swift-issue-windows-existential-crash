/// Minimal reproduction case for Swift compiler crash on Windows
/// when mangling existential type for debug info.
///
/// The crash occurs during IRGen when the compiler attempts to mangle
/// `any HTML.View` for DWARF debug information.
///
/// Key: The HTML namespace is defined in BaseModule (like WHATWG_HTML_Shared)
/// and extended here (like in HTML Renderable). This cross-module pattern
/// is what triggers the bug.

public import BaseModule

// MARK: - HTML.View (extends HTML from BaseModule)

extension HTML {
    /// A protocol representing HTML content.
    /// Extends the Renderable protocol from BaseModule.
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

// MARK: - AnyRenderable conformance

extension AnyRenderable: Renderable where Context == HTML.Context {
    public typealias Content = Never
    public typealias Output = UInt8

    public var body: Never { fatalError("body should not be called") }
}

extension AnyRenderable: HTML.View where Context == HTML.Context {}

public typealias AnyHTML = HTML.AnyView
