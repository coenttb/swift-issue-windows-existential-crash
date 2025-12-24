/// Minimal reproduction case for Swift compiler crash on Windows
/// when mangling existential type for debug info.
///
/// The crash occurs during IRGen when the compiler attempts to mangle
/// `any View` for DWARF debug information.

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

extension Never: View {
    public var body: Never { fatalError() }
}

public struct AnyView: View {
    public let base: any View

    /// This initializer triggers the crash on Windows.
    /// The crash occurs when mangling `any View` for debug info.
    public init(_ base: any View) {
        self.base = base
    }

    public var body: Never { fatalError() }
}
