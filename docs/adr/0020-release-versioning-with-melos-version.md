# 0020. Release versioning with melos version

- Status: Accepted, amended by [0027](0027-github-release-on-publish.md) (GitHub release on publish)
- Date: 2026-11-07

## Context

Since 0.1.0, packages are published with `melos publish`, which skips versions already on pub.dev and tags each one `<package>-v<version>` (AGENTS.md). Versions, sibling constraints and changelog headings were bumped by hand. That is easy to get wrong in a federated workspace: the 0.2.0 shared capture tap added a platform method that `earshot_classifier_darwin` needs, while its constraint still allowed the published platform interface without it.

Changelogs are written by hand, per package, and explain changes for app developers. Commit subjects alone are too terse for that.

## Decision

- **Versions come from Conventional Commits.** `dart run melos run release:version` runs `melos version` from an up-to-date `main`, on a new `release/<date>` branch. Melos looks at the commits that touched each package since its last `<package>-v<version>` tag and bumps it. Below 1.0.0 a breaking change bumps the minor version and a `feat` or `fix` bumps the patch. Packages that depend on a bumped sibling get the new constraint and a patch bump of their own.
- **Changelogs stay hand-written.** Every PR adds its entries under `## Unreleased` at the top of each changed package's `CHANGELOG.md`. Melos does not generate entries. Its `preCommit` hook, `tool/version_hook.dart`, renames `## Unreleased` to the new version, and adds a `## <version>` section with "Update dependencies." to packages bumped only because a dependency changed.
- **The hook also syncs what melos doesn't know about.** It sets `s.version` in every darwin podspec to the pubspec version, and `kEarshotVersion` in the example to the version of `earshot_plugin`, and stages those files.
- **The version commit goes through a PR.** It is titled `chore(release): publish packages` and is squash-merged like any other change. Melos does not tag at this step.
- **Publishing is unchanged.** From `main` after the merge, `release:check` and `release` publish the new versions in dependency order and push the tags, which become the baseline for the next `release:version`.
- **Forcing a version.** The milestones in the README feature checklist are targets. When the computed version falls short of one, the maintainer runs `melos version` with `--manual-version <package>:<minor|exact>` instead of the script's default.

## Consequences

- Sibling constraints always follow the versions they need, so published packages resolve together.
- Commit types now decide versions, so PR titles must use `feat`, `fix` and `!` deliberately. Commits that only use `docs`, `chore`, `ci` or `test` do not bump a package, and their `## Unreleased` notes wait for the next bump.
- A package can have no `## Unreleased` section and still be bumped as a dependent. Its changelog then only says its dependencies were updated.
