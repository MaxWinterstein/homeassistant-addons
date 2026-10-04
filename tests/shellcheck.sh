#!/usr/bin/env bash
#
# Lint the repository's shell scripts.
#
# Two things this handles that a bare `shellcheck **/*.sh` does not:
#
#   1. s6 `finish` and service scripts are often execlineb, not shell
#      (`#!/usr/bin/execlineb -S1`). Linting those as bash produces nothing but
#      false positives, so files are selected by shebang, not by filename.
#
#   2. Several older add-ons are not shellcheck-clean yet. Rather than leave
#      the whole repo ungated, those files are listed in
#      tests/shellcheck-baseline.txt and reported separately. Everything else
#      must stay clean, so new and freshly touched scripts cannot regress.
#
# Usage:
#   tests/shellcheck.sh              # gate: baselined files excused
#   tests/shellcheck.sh --all        # no excuses, show everything
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

BASELINE_FILE="tests/shellcheck-baseline.txt"
SHOW_ALL=0
[ "${1:-}" = "--all" ] && SHOW_ALL=1

# SC1091 is excluded repo-wide: these scripts source files that only exist
# inside the built container image, which shellcheck cannot resolve here.
EXCLUDES="SC1091"

is_shell_script() {
    local f="$1" first
    [ -f "$f" ] || return 1
    # Skip binaries (icons, screenshots) before reading a line from them:
    # grep -I reports binary files as non-matching.
    grep -Iq . "$f" 2>/dev/null || return 1
    first="$(head -1 "$f" 2>/dev/null)"
    case "$first" in
    '#!'*execlineb*) return 1 ;;
    '#!'*bashio*) return 0 ;; # with-contenv bashio is bash underneath
    '#!'*bash* | '#!'*/sh | '#!'*'/sh '* | '#!'*dash*) return 0 ;;
    esac
    # No usable shebang: fall back to the extension.
    case "$f" in
    *.sh | *.bash) return 0 ;;
    esac
    return 1
}

is_baselined() {
    [ -f "${BASELINE_FILE}" ] || return 1
    grep -vE '^\s*(#|$)' "${BASELINE_FILE}" | grep -qxF "$1"
}

# -c: tracked, -o: untracked, --exclude-standard: honour .gitignore.
# Plain `git ls-files` would silently skip brand-new scripts, so a script would
# only start being linted once it was committed — exactly the wrong moment.
mapfile -t candidates < <(git ls-files -co --exclude-standard)

gated_failures=0
baselined_failures=0
checked=0

for f in "${candidates[@]}"; do
    is_shell_script "$f" || continue
    checked=$((checked + 1))

    if out="$(shellcheck -s bash -e "${EXCLUDES}" -f gcc "$f" 2>&1)" && [ -z "$out" ]; then
        continue
    fi

    if [ "${SHOW_ALL}" = "0" ] && is_baselined "$f"; then
        baselined_failures=$((baselined_failures + 1))
        continue
    fi

    printf '\033[1m%s\033[0m\n' "$f"
    printf '%s\n\n' "$out"
    gated_failures=$((gated_failures + 1))
done

printf 'shellcheck: %d script(s) checked, %d failing' "${checked}" "${gated_failures}"
if [ "${baselined_failures}" -gt 0 ]; then
    printf ', %d baselined (see %s)' "${baselined_failures}" "${BASELINE_FILE}"
fi
printf '\n'

[ "${gated_failures}" -eq 0 ]
