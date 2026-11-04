# 0009. 0.0.1 is an API preview, not a name placeholder

- Status: Accepted
- Date: 2026-11-04

## Context

Package names need to be secured early. The pub.dev policy forbids publishing "solely to reserve a name".

## Decision

Every package's 0.0.1 ships the real public types from the API sketch: value types with `==`, `hashCode` and `toString`, enums, platform interfaces, and app-facing classes with full dartdoc. Only `MicrophonePermission.status()` works.

- **Streams** return `Stream.error(UnimplementedError(...))` and never throw synchronously.
- **Futures** complete with the same error.
- **`EarshotSound`** is withheld until the vocabulary validator exists. Only `SoundGroup` ships.
- **README and pubspec:** each package README has a pre-release banner linking to the root feature checklist, and each pubspec `description` starts with "Pre-release:".
- **Publishing:** packages are published manually under the author's personal pub.dev account, and transferred to a verified publisher later.

## Consequences

- People can review the API before the behaviour exists.
- Breaking changes stay allowed throughout 0.x, as a minor version bump.
