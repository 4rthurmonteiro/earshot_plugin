# 0027. A GitHub release on every publish

- Status: Accepted
- Date: 2026-11-13

## Context

`dart run melos run release` publishes the packages, tags each one `<package>-v<version>` and pushes the tags (ADR 0020). A tag alone doesn't create an entry on the repository's Releases page. The 0.1.0 release was written by hand. 0.2.0 and 1.0.0 got none until they were added later, so the page looked as if those versions didn't exist.

The packages share a version line but not always a version: a release only bumps the packages that changed, and the rest keep their previous version. `earshot_plugin` is bumped in every release, because it depends on all the others.

## Decision

- **The last step of `release`** runs `tool/github_release.dart`, after the tags are pushed.
- **One GitHub release per version**, on the `earshot_plugin-v<version>` tag, titled `earshot <version>` and marked as the latest. The version is read from the `earshot_plugin` pubspec.
- **The notes are built from the repository.** They contain:
  - a line naming the packages that kept their previous version;
  - a pub.dev link for every package with a `<package>-v<version>` tag;
  - the `## <version>` section of each of those packages' `CHANGELOG.md`.

  The changelogs stay the single source (ADR 0020).
- **It is safe to run again.** If the release already exists, the script reports it and does nothing, like `melos publish` with published versions. `--dry-run` prints the notes without creating anything.
- **It needs the GitHub CLI (`gh`)**, signed in, on the maintainer's machine.

## Consequences

- Every published version shows up on the Releases page, with the same structure.
- The notes have no hand-written summary. The maintainer can edit the release on GitHub afterwards.
- A release can't finish without `gh`. If it fails at this step, the packages and tags are already out, and running the script again, or `release` again, completes it.
