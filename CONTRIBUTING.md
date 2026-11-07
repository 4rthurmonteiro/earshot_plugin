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
dart run melos run pana           # pub.dev score with pana; needs `dart pub global activate pana`
```

CI requires every publishable package to get all of its pana points. pana resolves dependencies from pub.dev, so a package that needs a sibling version that is not published yet is skipped with a warning until the release.

## Pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/) for the PR title (`feat:`, `fix:`, `docs:`, `chore:` …). PRs are squash-merged, so the title becomes the commit message.
- Update the `CHANGELOG.md` of every package you change.
- If your PR implements an item of the feature checklist in the root [`README.md`](README.md), tick it (`- [x]`) in the same PR.
- A new architectural decision needs a new ADR in `docs/adr/`.
- CI builds the example for Android only. If your PR touches Swift or the darwin packages, build the example locally with `flutter build ios --simulator --debug` and `flutter build macos --debug` from `examples/earshot_example`, and say so in the PR.

## Releasing

Packages are published manually by the maintainer, from a clean and up-to-date `main`. Melos publishes them in dependency order, because each one resolves its siblings from pub.dev, skips the versions that are already published, and tags each one `<package>-v<version>`:

```bash
dart run melos run release:check    # validates every unpublished package with pub publish --dry-run
dart run melos run release          # publishes without asking, tags and pushes the tags
```

The first run needs `dart pub login`.
