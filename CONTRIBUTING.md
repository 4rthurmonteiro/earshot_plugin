# Contributing to earshot

Thanks for helping. This file is the short version for humans. The full conventions live in [`AGENTS.md`](AGENTS.md), and the reasons behind them are recorded in [`docs/adr/`](docs/adr/README.md).

## Setup

You need Flutter 3.47 or newer (Dart 3.13 or newer) and Very Good CLI:

```bash
dart pub global activate very_good_cli
```

Resolve the whole workspace from the repository root. There is a single `pubspec.lock`:

```bash
flutter pub get
```

## Everyday commands

Run these from the repository root. Melos comes from the workspace dev dependencies, so no global install is needed.

```bash
dart run melos run analyze        # flutter analyze --fatal-infos in every package
dart run melos run format:check   # dart format --set-exit-if-changed
dart run melos run test           # very_good test with 100% coverage
dart run melos run pigeon         # regenerate Pigeon code; commit the result
```

## Pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/) for the PR title (`feat:`, `fix:`, `docs:`, `chore:` …). PRs are squash-merged, so the title becomes the commit message.
- Update the `CHANGELOG.md` of every package you change.
- If your PR implements an item of the feature checklist in the root [`README.md`](README.md), tick it (`- [x]`) in the same PR.
- A new architectural decision needs a new ADR in `docs/adr/`.
- CI builds the example for Android only. If your PR touches Swift or the darwin packages, build the example locally with `flutter build ios --simulator --debug` and `flutter build macos --debug` from `examples/earshot_example`, and say so in the PR.

## Releasing

Packages are published manually by the maintainer, in dependency order, because each one resolves its siblings from pub.dev:

1. `earshot_capture_platform_interface`, `earshot_classifier_platform_interface`
2. `earshot_capture_android`, `earshot_capture_darwin`, `earshot_classifier_darwin`
3. `earshot_capture`, `earshot_classifier`
4. `earshot_level`
5. `earshot_plugin`

For each package, run `flutter pub publish --dry-run`, then `flutter pub publish`, then tag it `<package>-v<version>`.
