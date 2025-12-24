# Swift Compiler Crash: Windows Existential Type Mangling

Minimal reproduction case for a Swift compiler crash on Windows when mangling existential types for debug info.

## Bug Summary

The Swift compiler crashes on Windows (x86_64-unknown-windows-msvc) during IR generation when mangling an existential type (`any Protocol`) for DWARF debug information.

**Crash assertion:**
```
Assertion failed: isActuallyCanonicalOrNull() && "Forming a CanType out of a non-canonical type!"
```

## Reproduction

```bash
# On Windows with Swift 6.2
swift build -c debug
```

The crash occurs during debug build. Release builds may also be affected.

## Environment

- **Swift version:** 6.2.1 (swift-6.2.1-RELEASE)
- **Platform:** Windows (x86_64-unknown-windows-msvc)
- **Works on:** macOS, Linux (same Swift version)

## Minimal Code

This reproduction depends on [swift-html-rendering](https://github.com/coenttb/swift-html-rendering)
which contains `HTML.AnyView`. The crash occurs when compiling that library on Windows.

The bug involves a **cross-package** protocol hierarchy:

```swift
// Package: swift-whatwg-html (WHATWG_HTML_Shared module)
public enum WHATWG_HTML {}

// Package: swift-html-standard (HTML_Standard module)
public typealias HTML = WHATWG_HTML_Shared.WHATWG_HTML

// Package: swift-renderable (Rendering module)
public protocol Renderable {
    associatedtype Content
    associatedtype Context
    associatedtype Output
    var body: Content { get }
}

// Package: swift-html-rendering (HTML_Renderable module)
extension HTML {
    public protocol View: Renderable
    where Content: HTML.View, Context == HTML.Context, Output == UInt8 {
        var body: Content { get }
    }
}

extension HTML {
    public struct AnyView: HTML.View {
        public let base: any HTML.View  // Existential type - triggers crash

        // This initializer triggers the crash on Windows
        public init(_ base: any HTML.View) {
            self.base = base
            // ...
        }
    }
}
```

The key is that the `HTML` namespace is defined in one package (`swift-whatwg-html`) and the
`HTML.View` protocol is added via extension in a different package (`swift-html-rendering`).
This cross-package extension pattern combined with an existential stored property triggers the bug.

## Stack Trace

```
Assertion failed: isActuallyCanonicalOrNull() && "Forming a CanType out of a non-canonical type!",
file swift/include/swift/AST/Type.h, line 426

Stack dump:
0.  Program arguments: swift-frontend.exe -frontend -c ...
1.  Swift version 6.2.1 (swift-6.2.1-RELEASE)
2.  Compiling with the current language version
3.  While evaluating request IRGenRequest(IR Generation for file "...")
4.  While emitting IR SIL function "@$s...".
    for 'init(_:)' (at .../Crash.swift)
5.  While mangling type for debugger type 'any View'

Exception Code: 0x80000003
```

<details>
<summary>Full compiler crash output from CI</summary>

See: https://github.com/coenttb/swift-pdf/actions/runs/20463585119/job/58801803244

```
Assertion failed: isActuallyCanonicalOrNull() && "Forming a CanType out of a non-canonical type!", file C:\Users\swift-ci\jenkins\workspace\swift-6.2-windows-toolchain\swift\include\swift/AST/Type.h, line 426

Please submit a bug report (https://swift.org/contributing/#reporting-bugs) and include the crash backtrace.

Stack dump:
0.	Program arguments: C:\\Users\\runneradmin\\AppData\\Local\\Programs\\Swift\\Toolchains\\6.2.1+Asserts\\usr\\bin\\swift-frontend.exe -frontend -c -primary-file "D:\\a\\swift-pdf\\swift-pdf\\.build\\checkouts\\swift-html-rendering\\Sources\\HTML Renderable\\AsyncChannel+HTML.swift" ...
1.	Swift version 6.2.1 (swift-6.2.1-RELEASE)
2.	Compiling with the current language version
3.	While evaluating request IRGenRequest(IR Generation for file "D:\a\swift-pdf\swift-pdf\.build\checkouts\swift-html-rendering\Sources\HTML Renderable\HTML.AnyView.swift")
4.	While emitting IR SIL function "@$s18WHATWG_HTML_Shared0a1_B0O0B11_RenderableE7AnyViewVyAfcDE0F0_pcfC".
    for 'init(_:)' (at D:\a\swift-pdf\swift-pdf\.build\checkouts\swift-html-rendering\Sources\HTML Renderable\HTML.AnyView.swift:42:16)
5.	While mangling type for debugger type 'any HTML.View'

Exception Code: 0x80000003

 #0 0x00007ff62282d125 (swift-frontend.exe+0x6e4d125)
 #1 0x00007ffcb16b1989 (ucrtbase.dll+0xc1989)
 #2 0x00007ffcb1694ab1 (ucrtbase.dll+0xa4ab1)
 #3 0x00007ffcb16b2986 (ucrtbase.dll+0xc2986)
 #4 0x00007ffcb16b2b61 (ucrtbase.dll+0xc2b61)
 #5 0x00007ff61db614b1 (swift-frontend.exe+0x21814b1)
 #6 0x00007ff61db6b62b (swift-frontend.exe+0x218b62b)
 #7 0x00007ff61c427fab (swift-frontend.exe+0xa47fab)
 #8 0x00007ff61c42ab78 (swift-frontend.exe+0xa4ab78)
 #9 0x00007ff61c425f1e (swift-frontend.exe+0xa45f1e)
#10 0x00007ff61c425ae9 (swift-frontend.exe+0xa45ae9)
#11 0x00007ff61c561d42 (swift-frontend.exe+0xb81d42)
#12 0x00007ff61c55a1d9 (swift-frontend.exe+0xb7a1d9)
#13 0x00007ff61c56ef8a (swift-frontend.exe+0xb8ef8a)
#14 0x00007ff61c54acec (swift-frontend.exe+0xb6acec)
#15 0x00007ff61c549add (swift-frontend.exe+0xb69add)
#16 0x00007ff61c38a628 (swift-frontend.exe+0x9aa628)
#17 0x00007ff61c308921 (swift-frontend.exe+0x928921)
#18 0x00007ff61c312626 (swift-frontend.exe+0x932626)
#19 0x00007ff61c300297 (swift-frontend.exe+0x920297)
#20 0x00007ff61c30bf5d (swift-frontend.exe+0x92bf5d)
#21 0x00007ff61bf6c811 (swift-frontend.exe+0x58c811)
#22 0x00007ff61bf6cf5f (swift-frontend.exe+0x58cf5f)
#23 0x00007ff61bf6bcc4 (swift-frontend.exe+0x58bcc4)
#24 0x00007ff61bf6c17b (swift-frontend.exe+0x58c17b)
#25 0x00007ff61bf6e0e2 (swift-frontend.exe+0x58e0e2)
#26 0x00007ff61bdb92a0 (swift-frontend.exe+0x3d92a0)
#27 0x00007ff61bdb8e37 (swift-frontend.exe+0x3d8e37)
#28 0x00007ff62288cc08 (swift-frontend.exe+0x6eacc08)
#29 0x00007ffcb331e8d7 (KERNEL32.DLL+0x2e8d7)
#30 0x00007ffcb3d8c53c (ntdll.dll+0x8c53c)
```

</details>

## Expected Behavior

The compiler should successfully compile the code with debug info enabled, generating valid DWARF debug information for existential types.

## Actual Behavior

The compiler crashes with an assertion failure when attempting to mangle the existential type `any View` for debug info generation.

## CI Status

| Platform | Status |
|----------|--------|
| Windows | ❌ Crashes |
| macOS | ✅ Works |
| Linux | ✅ Works |

## Original Discovery

This bug was discovered in [coenttb/swift-pdf](https://github.com/coenttb/swift-pdf) CI:
- Failed run: https://github.com/coenttb/swift-pdf/actions/runs/20463585119/job/58801803244
- The crash occurs in the [swift-html-rendering](https://github.com/coenttb/swift-html-rendering) dependency

## Suggested Labels

`bug`, `crash`, `compiler`, `IRGen`, `Windows`, `existentials`, `debug info`
