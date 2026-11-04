# 0007. Swift Package Manager with CocoaPods fallback

- Status: Accepted
- Date: 2026-11-04

## Context

Flutter apps have used SwiftPM by default since Flutter 3.44, and CocoaPods is in maintenance mode. The Flutter docs still ask plugin authors to support both "until further notice". pana gives full platform points to a plugin with a `pluginClass` only if `darwin/<pkg>/Package.swift` exists.

## Decision

Both darwin packages ship with SwiftPM from 0.0.1:

- `darwin/<pkg>/Package.swift` uses swift-tools 5.9 and depends on `FlutterFramework`.
- Sources live in `Sources/<pkg>/`, along with `PrivacyInfo.xcprivacy`.
- A podspec points at the same sources and is kept as a fallback.

Minimum OS versions are fixed now, because raising them later breaks apps. They must match between `Package.swift` and the podspec:

| Package | iOS | macOS | Reason |
| --- | --- | --- | --- |
| `earshot_capture_darwin` | 13.0 | 10.15 | |
| `earshot_classifier_darwin` | 15.0 | 12.0 | SoundAnalysis `.version1` |

## Consequences

- Each example build must pass with SwiftPM on (in CI) and with SwiftPM off (checked locally before each release).
- Drop the podspec once the Flutter docs allow SwiftPM-only plugins.
