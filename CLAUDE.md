# Claude Instructions

## General

- Always `git pull --rebase` before pushing to avoid rejected pushes

## Changelog and releasing

Releases are batched, not per-commit. Do **not** bump `version:` in `config.yaml` and do **not** edit an
add-on's `CHANGELOG.md` by hand.

- A PR that changes an add-on adds a towncrier news fragment instead, one line describing the change:
  `uvx towncrier create --dir <addon> --content "Fixed X" <PR-number>.fixed.md`
  Types: `added`, `changed`, `deprecated`, `fixed`, `removed`, `security`.
- Renovate PRs get their fragment written automatically by `update-changelog.yml`, named after the
  dependency (`+uv.changed.md`) so later bumps overwrite it.
- A release bumps the version and folds all pending fragments into `CHANGELOG.md`. There is exactly one
  way to do that, `scripts/release-addon.sh`, reached either locally via `task release -- <addon> <version>`
  or by commenting `/release <addon>` (or adding the `release` label) on a PR. The resulting `config.yaml`
  change is what triggers `onpush_build.yaml` to publish the new image tag.

So a fix can sit on `main` unreleased. It reaches users at the next release of that add-on, which is
deliberate — several small changes ship as one version rather than one each.

Docs, tests, CI and repo-level files never need any of this: they do not end up in the image.
