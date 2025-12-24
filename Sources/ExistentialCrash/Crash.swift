/// Minimal reproduction case for Swift compiler crash on Windows
/// when mangling existential type for debug info.
///
/// The crash occurs during IRGen when the compiler attempts to mangle
/// `any HTML.View` for DWARF debug information.
///
/// This file simply imports and uses the HTML.AnyView type from swift-html-rendering.
/// The crash is in the swift-html-rendering library itself.

public import HTML_Renderable

// Just re-export to ensure the library is compiled
public typealias CrashingType = HTML.AnyView

// Use the type to ensure it's compiled
public func createAnyView(_ content: any HTML.View) -> HTML.AnyView {
    HTML.AnyView(content)
}
