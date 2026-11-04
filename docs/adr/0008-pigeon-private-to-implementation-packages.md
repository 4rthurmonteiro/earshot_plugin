# 0008. Pigeon, private to implementation packages

- Status: Accepted
- Date: 2026-11-04

## Context

Native and Dart code need a typed channel. Validating the toolchain early (codegen, SwiftPM and podspec compilation, Kotlin/Gradle) lowers the risk of the capture milestone.

## Decision

- Each implementation package owns its `pigeons/messages.dart`.
- Generated Dart, Kotlin and Swift code is committed and excluded from analysis and coverage.
- CI fails if regenerating the code produces a diff.
- Pigeon types never appear in the public API. Implementations map them to platform-interface types.
- In 0.0.1 the only host call is `microphonePermissionStatus()`, implemented for real on Android, iOS and macOS.
- PCM streaming uses `@EventChannelApi` starting with 0.1.0.
- `earshot_classifier_darwin` adopts Pigeon together with the SoundAnalysis backend.

## Consequences

- Pigeon contract changes are not breaking for package users.
- Dart implementation classes take the generated host API in their constructor, so tests can mock it with mocktail.
