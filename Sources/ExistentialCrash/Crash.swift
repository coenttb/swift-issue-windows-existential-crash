/// Minimal reproduction case for Swift compiler crash on Windows
/// when mangling existential type for debug info.
///
/// The crash occurs during IRGen when the compiler attempts to mangle
/// `any HTML.View` for DWARF debug information.
///
/// Key: The HTML namespace is defined in a DIFFERENT PACKAGE (BaseModule)
/// and the View protocol is added via extension here. This cross-package
/// extension pattern combined with existential types triggers the bug.

import BaseModule

// MARK: - Renderable Protocol

public protocol Renderable {
    associatedtype Content
    associatedtype Context
    associatedtype Output
    var body: Content { get }
}

// MARK: - HTML.View Protocol (extends HTML from other package)

extension HTML {
    public protocol View: Renderable
    where Content: HTML.View, Context == HTML.Context, Output == UInt8 {
        var body: Content { get }
    }
}

// MARK: - Never conformance

extension Never: HTML.View {
    public var body: Never { fatalError() }
}

// MARK: - HTML.AnyView (THIS TRIGGERS THE CRASH)

extension HTML {
    public struct AnyView: HTML.View, @unchecked Sendable {
        /// The existential type that causes the crash during debug info mangling
        public let base: any HTML.View

        /// This initializer triggers the crash on Windows.
        public init(_ base: any HTML.View) {
            self.base = base
        }

        public var body: Never { fatalError() }
    }
}
