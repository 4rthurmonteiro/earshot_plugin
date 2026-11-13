# 0021. Public API stability from 1.0.0

- Status: Accepted, amended by [0025](0025-level-type-names.md) (closed enums renamed)
- Date: 2026-11-12

## Context

Since 0.0.1 the public API has been a preview, and breaking changes ship as a minor version bump (ADR 0009, ADR 0020). 1.0.0 freezes it: from then on, a breaking change needs a major version.

Several public enums will gain values after 1.0.0. The vocabulary grows as backends add labels, new engines become backends, and new failures need error codes. In Dart, adding a value to an enum breaks every `switch` that lists all the values without a wildcard: the app no longer compiles. Taken literally, every new `EarshotSound` would be a major version.

The alternative is to replace those enums with classes that have `static const` instances, which can never be switched on exhaustively. That gives up exhaustiveness checks and the enum API (`values`, `name`, `asNameMap`) everywhere, to protect the few apps that switch without a wildcard.

The packages also depend on each other's types. `earshot_capture` and `earshot_classifier` re-export types from their platform interfaces, `earshot_level` takes `PcmChunk` from the capture platform interface, and `earshot_plugin` re-exports every app-facing package. A breaking change in one package is then a breaking change in every package that exposes its types.

## Decision

- **The public API** of a package is everything exported by its `lib/<package>.dart`. Members marked `@internal` and files under `lib/src/` that the library does not export are not part of it.
- **Breaking changes need a major version** from 1.0.0. They include:
  - removing or renaming an exported type, member or enum value;
  - changing a signature or a default value;
  - changing the type or code of an error delivered on a stream;
  - changing documented behaviour.
- **Open enums can grow in a minor version.** Adding a value to one of these enums is not a breaking change:
  - `EarshotSound`, `SoundGroup` and `ClassifierBackend`;
  - `CaptureErrorCode` and `EarshotErrorCode`;
  - `SampleRate`, `CaptureState` and `MicrophonePermissionStatus`.

  The dartdoc of every open enum says so, and tells apps to add a wildcard (`_`) case when they switch on it. The READMEs show such a switch.
- **Closed enums** are `Weighting` and `Response`: IEC 61672-1 defines their values. A new value is a major version.
- **The vocabulary is data.** Adding a raw label to an `EarshotSound`, or moving a label to another sound or group, is a minor version, listed in the changelog. Removing an `EarshotSound` value is still a major version.
- **Platform interfaces** keep the rule of `plugin_platform_interface` that implementations `extend` them and never `implement` them. A new method with a default implementation is a minor version. A new abstract method, or a change to an existing method, is a major version.
- **Breaking changes travel with re-exports.** When a package gets a major version, every package that re-exports its types, or takes them in its public API, gets a major version too. `melos version` only bumps dependents by a patch (ADR 0020), so the maintainer forces those majors with `--manual-version`.
- **Pre-release markers go at 1.0.0.** The "Pre-release:" prefix of every pubspec `description` and the pre-release banner of every README are removed in the 1.0.0 release.

This supersedes ADR 0009, whose rule that breaking changes ship as a minor version ends at 1.0.0.

## Consequences

- New sounds, backends and error codes don't force a major version, and apps keep exhaustive switches on closed enums.
- An app that switches on an open enum without a wildcard can stop compiling after a minor update. The dartdoc and the READMEs warn about it, but the compiler doesn't.
- A major version of a platform interface or of `earshot_level` cascades up to `earshot_plugin`, so changes to shared types such as `PcmChunk` need care.
