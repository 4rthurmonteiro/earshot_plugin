# AGENTS.md

Instructions for AI coding agents (and humans) working in this repository. Why things are this way is recorded in [`docs/adr/`](docs/adr/README.md). Read the relevant ADR before changing a decision; to change one, write a new ADR that supersedes it.

## What this is

`earshot` is a set of federated Flutter plugins for on-device ambient listening:

- how loud it is (dB(A), Leq, calibration)
- what is sounding (sound classification)

It offers the same API on Android, iOS and macOS, never uses the network, and no audio leaves the device.

## Repository layout

```
pubspec.yaml                 # workspace root (earshot_workspace) + melos config
packages/
  earshot_capture/           # microphone → PCM (federated)
    earshot_capture/                       # app-facing
    earshot_capture_platform_interface/    # pure Dart
    earshot_capture_android/               # Kotlin + Pigeon
    earshot_capture_darwin/                # Swift (iOS + macOS) + Pigeon, SwiftPM + podspec
  earshot_level/             # pure Dart: weighting, Leq, calibration
  earshot_classifier/        # sound classification (federated)
    earshot_classifier/                    # app-facing + inline Android (Dart YAMNet backend)
    earshot_classifier_platform_interface/ # pure Dart
    earshot_classifier_darwin/             # Swift (iOS + macOS), SoundAnalysis backend
  earshot_plugin/            # umbrella: level + classifier in one stream
examples/earshot_example/    # demo app (android, ios, macos), not published
docs/adr/                    # architecture decision records
```

`docs/brainstorm/` and `docs/plan/` are local working folders and are git-ignored. Never commit them.

## Commands

Run all commands from the repository root. You need Flutter ≥ 3.47 (Dart ≥ 3.13).

```bash
flutter pub get                     # resolves the whole workspace (single pubspec.lock)
dart run melos run analyze          # flutter analyze --fatal-infos in every package
dart run melos run format:check     # dart format --set-exit-if-changed
dart run melos run test             # very_good test --min-coverage 100 (needs very_good_cli)
dart run melos run pigeon           # regenerate Pigeon code; commit the result
dart run melos run release:check    # pub publish --dry-run for every unpublished package
```

## Conventions

- **Language:** English for code, dartdoc, READMEs, CHANGELOGs, ADRs and commits.
- **Lints:** `very_good_analysis`, with no ignores unless a justification comment explains them. Every public member needs dartdoc.
- **Tests:**
  - 100% coverage is required. Generated files (`*.g.dart`) are excluded.
  - Use `mocktail`. Platform mocks use `MockPlatformInterfaceMixin`.
  - App-facing tests check that calls are delegated to the platform.
- **Workspace:**
  - Every package declares `resolution: workspace` and its own dev_dependencies (`very_good_analysis`, `mocktail`, and `test` or `flutter_test`).
  - Packages depend on each other through version constraints, never `path:`.
  - Never add a `pubspec.yaml` that isn't listed as a workspace member. Use `example/README.md` for package examples.
- **Federation:**
  - Platform interfaces are pure Dart.
  - Implementation packages are named by platform (`_android`, `_darwin`). Backends are named by engine (`apple`, `yamnet`).
  - The app-facing package endorses its implementations with `default_package`.
- **Pigeon:**
  - Each implementation package owns `pigeons/messages.dart`, and the generated Dart, Kotlin and Swift code is committed.
  - Pigeon types never appear in the public API.
  - CI fails if `melos run pigeon` produces a diff.
- **Darwin:**
  - iOS and macOS share sources (`sharedDarwinSource: true`).
  - Every darwin package ships both `darwin/<pkg>/Package.swift` (SwiftPM) and a podspec, and they must keep identical sources and minimum OS versions.
  - On iOS, both darwin packages activate and release the `AVAudioSession` only through `EarshotAudioSession.swift`, and the two copies of that file must stay identical (ADR 0017).
  - Minimum OS versions: `earshot_capture_darwin` iOS 13 / macOS 10.15, `earshot_classifier_darwin` iOS 15 / macOS 12. Never raise them without an ADR.
- **Value types:** write `==`, `hashCode` and `toString` by hand (no `equatable`). Prefer enums to asserts for constrained values.
- **No `print`** in `lib/`. Each `listen()` gets its own subscription, and cancelling it stops the native work.
- **Privacy:**
  - No network calls and no telemetry.
  - Never write audio to disk by default.
  - Permission status queries must never prompt the user.
- **Alarms disclaimer:** dartdoc and READMEs for alarm-related sounds state that earshot is informational and not a certified detector.

## Workflow

- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:` …). PRs are squash-merged, and the PR title becomes the commit message, so it must be semantic.
- **Feature checklist:** the root `README.md` has a feature checklist for each version. When a PR implements a feature, tick its item (`- [x]`) in the same PR. On release, append the version, for example `(0.1.0)`.
- **Changelogs:** update the `CHANGELOG.md` of every package you change.
- **New decisions:** a new architectural decision gets a new ADR in `docs/adr/`, numbered sequentially and added to the index.

## Releasing

Packages are published manually by the maintainer with Melos, which publishes them in dependency order (each one resolves its siblings from pub.dev), skips the versions that are already published, and tags each one `<package>-v<version>`:

```bash
dart run melos run release:check    # pub publish --dry-run for every unpublished package
dart run melos run release          # publish, tag and push the tags; needs a clean, up-to-date main
```

Never publish from an agent session.
