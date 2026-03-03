# Swift Stack Profile

Stack profile template for Swift / iOS / macOS projects. Used by `/arch:init` to generate project-specific configuration.

## Detection

| Indicator | Source |
|-----------|--------|
| `Package.swift` | Swift Package Manager project |
| `*.xcodeproj` / `*.xcworkspace` | Xcode project |
| `Package.swift` → `swift-tools-version` | Swift tools version |
| `.swift-version` | Swift version file |

## Version Detection

```
grep 'swift-tools-version' Package.swift | head -1 | sed 's/.*swift-tools-version:[[:space:]]*//'
```

For Xcode projects without SPM, infer from `SWIFT_VERSION` build setting or default to latest stable.

## Framework Detection

| File/Pattern | Framework |
|-------------|-----------|
| `import SwiftUI` in sources | SwiftUI |
| `import UIKit` in sources | UIKit |
| `import AppKit` in sources | AppKit (macOS) |
| `import SwiftData` | SwiftData |
| `import CoreData` | Core Data |
| `import Vapor` in Package.swift | Vapor (server-side) |
| `import ComposableArchitecture` | TCA (Point-Free) |

## Platform Detection

| File/Pattern | Platform |
|-------------|----------|
| `platforms: [.iOS(` in Package.swift | iOS |
| `platforms: [.macOS(` in Package.swift | macOS |
| `platforms: [.watchOS(` in Package.swift | watchOS |
| `platforms: [.tvOS(` in Package.swift | tvOS |
| `platforms: [.visionOS(` in Package.swift | visionOS |

## Rules Content

Generate as `.claude/rules/stack-swift.md`:

```markdown
# Swift Stack Rules

## Version: Swift {version}, Platform: {platform} {min_version}+

## Modern SwiftUI Patterns (iOS 17+ / macOS 14+)
- Use `@Observable` macro — NOT `ObservableObject` + `@Published`
- Use `NavigationStack` — NOT `NavigationView`
- Use `foregroundStyle()` — NOT `foregroundColor()`
- Use `clipShape(.rect(cornerRadius:))` — NOT `.cornerRadius()`
- Use `onChange(of:)` two-parameter closure — NOT single-parameter
- Use `@Bindable` for bindings from `@Observable` types
- Use `#Preview` macro — NOT `PreviewProvider`

## Swift Concurrency
- Use `async`/`await` for asynchronous work
- Use `actor` for thread-safe mutable state
- NEVER use `DispatchQueue.main.async` — use `@MainActor` instead
- Use structured concurrency (`TaskGroup`, `async let`) over unstructured `Task {}`
- Always propagate cancellation — check `Task.isCancelled`
- All `@MainActor` code must be explicitly annotated

## Error Handling
- Use typed `throws` (Swift 6.0+) where applicable
- Define error enums conforming to `Error` and `LocalizedError`
- Use `Result` type for callbacks that can't be async
- Provide `localizedDescription` for user-facing errors

## SwiftUI Architecture
- Keep views small — extract subviews when body exceeds ~50 lines
- Use `@State` for view-local state, `@Environment` for shared state
- Avoid complex view type expressions (triggers "unable to type-check in reasonable time")
- Use `ViewModifier` for reusable view modifications

## Project File Safety
- NEVER modify `.pbxproj` files directly — one corruption wastes hours
- Create source files with proper directory structure; add to Xcode manually
- Use Swift Package Manager for dependency management when possible

## Anti-Patterns
- No `ObservableObject` / `@Published` on iOS 17+ — use `@Observable`
- No `NavigationView` — use `NavigationStack` / `NavigationSplitView`
- No `foregroundColor()` — use `foregroundStyle()`
- No `DispatchQueue.main.async` — use `@MainActor`
- No force unwrap (`!`) outside of tests — use `guard let` or `if let`
- No direct `.pbxproj` modification

## Verification
After editing Swift files, run: `xcodebuild build -quiet` or `swift build`
```

## CLAUDE.md Section

```markdown
### Swift {version} ({platform} {min_version}+)
**Build & verify:** `swift build` or `xcodebuild build -quiet`
**Modern SwiftUI:** `@Observable`, `NavigationStack`, `foregroundStyle()`, `#Preview`
**Concurrency:** `@MainActor` not `DispatchQueue.main.async`, structured concurrency
**Safety:** Never modify `.pbxproj` directly; extract views when body > 50 lines
```

## Settings Permissions

```json
["Bash(swift build*)", "Bash(swift test*)", "Bash(xcodebuild *)", "Bash(xcrun *)"]
```

## Hook Verification

File extension match: `.swift`
Verification command: `swift build 2>&1 | tail -20`
Fallback: `xcodebuild build -quiet 2>&1 | tail -20`

## Test Framework Detection

| Pattern | Framework | Command |
|---------|-----------|---------|
| `import XCTest` | XCTest | `swift test` or `xcodebuild test` |
| `import Testing` | Swift Testing (5.9+) | `swift test` |
| `Quick` / `Nimble` in deps | Quick/Nimble | `swift test` |

## MCP Recommendations

| MCP Server | Purpose | Install |
|-----------|---------|---------|
| `getsentry/XcodeBuildMCP` | Build, test, simulator, LLDB, UI automation (59 tools) | `claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp` |
| `joshuayoes/ios-simulator-mcp` | Simulator UI control, screenshots | `claude mcp add ios-simulator -- npx -y ios-simulator-mcp@latest` |

## Known Pitfalls

1. **Swift Concurrency (async/await, actors)**: Universally cited as highest-risk area. Claude writes competent Swift 5.5-era code but struggles with actor isolation semantics, forward progress contracts, and structured concurrency. Require human review.
2. **Deprecated API defaults**: Claude generates `foregroundColor()`, `NavigationView`, `ObservableObject`, `cornerRadius()` by default. Explicit CLAUDE.md prohibitions fix this completely.
3. **iOS version targeting confusion**: SwiftUI APIs change significantly between iOS 16/17/18. Without explicit version pinning, Claude generates code for the wrong OS version.
4. **`.pbxproj` corruption**: Community consensus — never let Claude modify Xcode project files. Create files, add to Xcode manually.
5. **SwiftUI view complexity**: Complex view type expressions trigger compiler errors ("unable to type-check in reasonable time"). Claude doesn't naturally decompose large views.
6. **Hallucinated APIs**: Claude generates plausible-looking but nonexistent Swift/SwiftUI APIs. Always verify with `xcodebuild`.
