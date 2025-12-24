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
# On Windows with Swift 6.0+
swift build -c debug
```

The crash occurs during debug build. Release builds are not affected.

## Environment

- **Swift version:** 6.0+ (tested with 6.0.3 and 6.2.1)
- **Platform:** Windows (x86_64-unknown-windows-msvc)
- **Works on:** macOS, Linux (same Swift version)

## Minimal Code

This is a **standalone reproduction with no external dependencies**.

The bug involves a cross-module protocol extension pattern:

```swift
// === BaseModule ===
// Defines the namespace

public enum HTML {}

extension HTML {
    public struct Context: Sendable {
        public init() {}
    }
}

// === ExistentialCrash ===
// Extends the namespace with a protocol

import BaseModule

public protocol Renderable {
    associatedtype Content
    associatedtype Context
    associatedtype Output
    var body: Content { get }
}

extension HTML {
    public protocol View: Renderable
    where Content: HTML.View, Context == HTML.Context, Output == UInt8 {
        var body: Content { get }
    }
}

extension HTML {
    public struct AnyView: HTML.View {
        public let base: any HTML.View  // Existential type

        // This initializer triggers the crash on Windows
        public init(_ base: any HTML.View) {
            self.base = base
            // ...
        }

        public var body: Never { fatalError() }
    }
}
```

The key elements:
1. A namespace enum (`HTML`) defined in one module
2. A protocol (`HTML.View`) added via extension in a different module
3. A struct storing an existential (`any HTML.View`) of that protocol
4. An initializer taking that existential type

## Stack Trace

```
Assertion failed: isActuallyCanonicalOrNull() && "Forming a CanType out of a non-canonical type!",
file swift/include/swift/AST/Type.h, line 426

Stack dump:
0.  Program arguments: swift-frontend.exe -frontend -c ...
1.  Swift version 6.0.3 (swift-6.0.3-RELEASE)
2.  Compiling with the current language version
3.  While evaluating request IRGenRequest(IR Generation for file "...")
4.  While emitting IR SIL function "@$s...".
    for 'init(_:)' (at .../Crash.swift)
5.  While mangling type for debugger type 'any HTML.View'

Exception Code: 0x80000003
```

## Expected Behavior

The compiler should successfully compile the code with debug info enabled, generating valid DWARF debug information for existential types.

## Actual Behavior

The compiler crashes with an assertion failure when attempting to mangle the existential type `any HTML.View` for debug info generation.

## CI Status

| Platform | Status |
|----------|--------|
| macOS | ✅ Works |
| Linux | ✅ Works |
| Windows | ❌ Crashes |

**Reproduction CI:** https://github.com/coenttb/swift-issue-windows-existential-crash/actions

## Workaround

Disable debug info generation on Windows:
```bash
swift build -c debug -Xswiftc -gnone
```

Or use release builds which don't include debug info by default.

## Original Discovery

This bug was discovered in [coenttb/swift-pdf](https://github.com/coenttb/swift-pdf) CI:
- Failed run: https://github.com/coenttb/swift-pdf/actions/runs/20463585119/job/58801803244
- The crash occurs in the [swift-html-rendering](https://github.com/coenttb/swift-html-rendering) dependency

A version of this reproduction using the actual packages is available on the [`with-dependencies`](https://github.com/coenttb/swift-issue-windows-existential-crash/tree/with-dependencies) branch.

## Suggested Labels

`bug`, `crash`, `compiler`, `IRGen`, `Windows`, `existentials`, `debug info`
