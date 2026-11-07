<!--
  Thanks for contributing! The short version of the conventions is in
  CONTRIBUTING.md. PRs are squash-merged, so the PR title becomes the commit
  message and must follow Conventional Commits (feat:, fix:, docs:, chore: ...).
-->

## Description

<!-- What changes, and why. Link the issue it closes: "Closes #123". -->

## Type of change

<!-- Put an `x` in every box that applies. -->

- [ ] ✨ `feat` New feature
- [ ] 🛠️ `fix` Bug fix
- [ ] ❌ `!` Breaking change
- [ ] 📝 `docs` Documentation
- [ ] 🧹 `refactor` Code refactor
- [ ] ✅ `ci` Build or CI configuration
- [ ] 🗑️ `chore` Chore

## Checklist

- [ ] `dart run melos run analyze`, `format:check` and `test` pass (100% coverage).
- [ ] The `CHANGELOG.md` of every changed package is updated.
- [ ] If this implements an item of the README feature checklist, it is ticked.
- [ ] If Pigeon definitions changed, `dart run melos run pigeon` was run and the result is committed.
- [ ] If this touches Swift or a darwin package, the example was built for iOS and macOS locally.
- [ ] A new architectural decision has a new ADR in `docs/adr/`.
