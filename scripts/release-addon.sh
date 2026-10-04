#!/usr/bin/env bash
#
# Releases one add-on: bumps the version in its config.yaml and turns the
# pending towncrier fragments in <addon>/changelog.d/ into a CHANGELOG.md entry.
#
# This is the only release path — `task release` and the `/release` comment
# workflow both call it, so pending fragments never get skipped.
#
#   scripts/release-addon.sh <addon> <version>
#
# Describe changes first, e.g.:
#   uvx towncrier create --dir cups --content "Fixed X" 123.fixed.md
set -euo pipefail

usage() {
    echo "usage: $0 <addon> <version>" >&2
    exit 2
}

[ $# -eq 2 ] || usage
ADDON="${1%/}"
VERSION="${2#v}"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

CONFIG="${ADDON}/config.yaml"
[ -f "${CONFIG}" ] || {
    echo "no ${CONFIG} — is '${ADDON}' an add-on directory?" >&2
    exit 1
}
[ -f "${ADDON}/CHANGELOG.md" ] || {
    echo "${ADDON} has no CHANGELOG.md" >&2
    exit 1
}
[[ "${VERSION}" =~ ^[0-9]+(\.[0-9]+)+$ ]] || {
    echo "version must look like 1.2.3 or 1.2.3.4, got '${VERSION}'" >&2
    exit 1
}

# towncrier would happily write an empty release; refuse instead.
shopt -s nullglob
fragments=("${ADDON}"/changelog.d/*.md)
[ ${#fragments[@]} -gt 0 ] || {
    echo "${ADDON}/changelog.d/ has no fragments — describe the change first, e.g.:" >&2
    echo "  uvx towncrier create --dir ${ADDON} --content 'Fixed X' +fix-x.fixed.md" >&2
    exit 1
}

CURRENT="$(sed -n 's/^version:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' "${CONFIG}")"
[ -n "${CURRENT}" ] || {
    echo "could not read the version from ${CONFIG}" >&2
    exit 1
}
[ "${CURRENT}" != "${VERSION}" ] || {
    echo "${ADDON} is already at ${VERSION}" >&2
    exit 1
}

sed -i.bak "s/^version:.*/version: ${VERSION}/" "${CONFIG}" && rm -f "${CONFIG}.bak"

TOWNCRIER=(uvx --quiet towncrier)
# In CI the project environment already has towncrier installed.
if [ -n "${CI:-}" ]; then TOWNCRIER=(uv run towncrier); fi
"${TOWNCRIER[@]}" build --yes --dir "${ADDON}" --version "${VERSION}" --config pyproject.toml

# towncrier's Markdown template leaves two blank lines after the new entry;
# prettier (pre-commit) squashes them, so do it here instead of in a fix-up commit.
cat -s "${ADDON}/CHANGELOG.md" >"${ADDON}/CHANGELOG.md.tmp" && mv "${ADDON}/CHANGELOG.md.tmp" "${ADDON}/CHANGELOG.md"

echo "${ADDON}: ${CURRENT} -> ${VERSION} (${#fragments[@]} fragment(s))"
