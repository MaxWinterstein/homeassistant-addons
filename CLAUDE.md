# Claude Instructions

## General

- Bump the version on **every commit** that changes an add-on, no matter how small the change. Exempt: pure repo tooling (`.github/`, `tests/`, `scripts/`), and Renovate dependency bumps and `changelog.d/` fragments, which are batched until the next release
- Never edit `CHANGELOG.md` by hand. Describe the change as a towncrier fragment in `<addon>/changelog.d/` (e.g. `uvx towncrier create --dir cups --content "Fixed X" +fix-x.fixed.md`), then release with `task release -- <addon> <version>`, which bumps the version and builds `CHANGELOG.md` from all pending fragments
- Always `git pull --rebase` before pushing to avoid rejected pushes
