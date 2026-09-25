# Claude Instructions

## General

- Always `git pull --rebase` before pushing to avoid rejected pushes

## Changelog and releasing

Releases are batched, not per-commit. Do **not** bump `version:` in `config.yaml` and do **not** edit an
add-on's `CHANGELOG.md` by hand.

- A PR that changes an add-on adds a towncrier news fragment instead:
  `<addon>/changelog.d/<PR-number>.<type>.md`, one line describing the change.
  Types: `added`, `changed`, `deprecated`, `fixed`, `removed`, `security`.
- Renovate PRs get their fragment written automatically by `update-changelog.yml`.
- Commenting `/release <addon>` (or adding the `release` label to a PR) is what bumps the version, runs
  `towncrier build` to fold the fragments into `CHANGELOG.md`, and pushes. That config change is what
  triggers `onpush_build.yaml` to publish the new image tag.

So a fix can sit on `main` unreleased. It reaches users at the next `/release` of that add-on, which is
deliberate — several small changes ship as one version rather than one each.

Docs, tests, CI and repo-level files never need any of this: they do not end up in the image, and
`.github/paths-filter.yml` excludes them from triggering a build.
