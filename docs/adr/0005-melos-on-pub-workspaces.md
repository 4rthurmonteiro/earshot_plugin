# 0005. Melos 8 on Dart pub workspaces

- Status: Accepted
- Date: 2026-11-04

## Context

The repo holds 9 publishable packages plus an example app. The handover left "melos vs pub workspaces" open. Melos 7+ is built on pub workspaces, so the two are not alternatives.

## Decision

- The root `pubspec.yaml` (`earshot_workspace`, `publish_to: none`) lists every member under `workspace:` and holds Melos 8 config under `melos:`.
- Every member declares `resolution: workspace`.
- There is a single committed `pubspec.lock`.
- In CI, Melos runs through `dart run melos`.
- Lints use `very_good_analysis`, and coverage is 100% via `very_good test`.
- The SDK floor is the current stable: Dart ^3.13, Flutter >=3.47.

## Consequences

- One dependency resolution covers the whole repo, so every package must agree on dependency versions.
- A stray non-member `pubspec.yaml` (for example a generated `example/` app) breaks resolution. Packages use `example/README.md` instead.
- pana and publish dry-runs resolve sibling packages from pub.dev, so they can only run in CI after 0.0.1 is live.
- Release automation (`melos version` with Conventional Commits) is configured starting with 0.1.0. Version 0.0.1 is set by hand.
