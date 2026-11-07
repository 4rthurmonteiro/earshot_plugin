# 0019. pana in CI

- Status: Accepted
- Date: 2026-11-07

## Context

pub.dev scores every published package with pana, out of 160 points: file conventions, documentation, platform support, static analysis and up-to-date dependencies. A lost point only shows up after publishing, when it is too late to fix that version. CI already runs stricter lints than pana (`very_good_analysis`), but it never checks what pub.dev checks.

pana resolves a package's dependencies from pub.dev, never from the workspace. It ignores `pubspec_overrides.yaml`, and `--project-root` only copies the workspace. A package therefore cannot be scored while it depends on a sibling version that is not published yet. That happens in every release cycle of a federated plugin, because the app-facing and implementation packages need the platform interface first.

## Decision

- `dart run melos run pana` runs `tool/pana_check.dart` in every publishable package, one at a time. The script runs pana with `--project-root` set to the workspace root, and passes only when the package gets every point.
- When pana cannot resolve a package because a constraint names an `earshot_*` version that is not on pub.dev, the script skips the package with a warning (a GitHub annotation in CI) instead of failing. The package is scored once that version is published.
- Any other lost point fails the script and prints the sections that lost points.
- CI runs the script in its own `pana` job, with pana pinned to a fixed version.

## Consequences

- Every publishable package must keep a perfect pana score.
- The check also catches sibling constraints that are too loose. A constraint that still allows a published sibling without a new API it needs makes the package fail static analysis, until the next version bump raises the constraint.
- Packages that wait for an unreleased sibling are not scored between releases. `release:check` still validates them with `pub publish --dry-run` before publishing.
- The job takes about a minute per package.
