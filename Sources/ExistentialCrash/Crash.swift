/// Minimal reproduction case for Swift compiler crash on Windows
/// when mangling existential type for debug info.
///
/// The crash occurs during IRGen when the compiler attempts to mangle
/// `any HTML.View` for DWARF debug information.
///
/// Key: The HTML namespace is defined in BaseModule and the View protocol
/// is added via extension here. This cross-module extension pattern
/// combined with existential types triggers the bug.

public import BaseModule

// MARK: - Renderable Protocol (simplified from swift-renderable)

public protocol Renderable {
    associatedtype Content
    associatedtype Context
    associatedtype Output
    var body: Content { get }
}

// MARK: - HTML.View Protocol (extends HTML from BaseModule)

extension HTML {
    /// A protocol representing HTML content.
    public protocol View: Renderable
    where Content: HTML.View, Context == HTML.Context, Output == UInt8 {
        @HTML.Builder var body: Content { get }
    }
}

extension HTML.View {
    @inlinable
    @_disfavoredOverload
    public static func _render(_ html: Self, context: inout HTML.Context) {
        // Simplified render implementation
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

        private let renderFunction: (inout HTML.Context) -> Void

        public init<T: HTML.View>(_ base: T) {
            self.base = base
            self.renderFunction = { context in
                T._render(base, context: &context)
            }
        }

        /// This initializer triggers the crash on Windows.
        /// The crash occurs when mangling `any HTML.View` for debug info.
        public init(_ base: any HTML.View) {
            if let anyView = base as? HTML.AnyView {
                self = anyView
            } else {
                self.base = base
                self.renderFunction = { context in
                    func render<T: HTML.View>(_ html: T) {
                        T._render(html, context: &context)
                    }
                    render(base)
                }
            }
        }

        public var body: Never { fatalError("body should not be called") }
    }
}
