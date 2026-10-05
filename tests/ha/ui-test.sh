#!/usr/bin/env bash
#
# Browser test: open an installed add-on's ingress page in the real Home
# Assistant frontend and check that the add-on's own UI loads in it.
#
#   tests/ha/ui-test.sh <addon-directory> [screenshot.png]
#
# Expects the test HA from supervisor-up.sh (onboarded) and the add-on
# installed and running, e.g. via `KEEP=1 tests/ha/addon-test.sh <addon>`,
# or just `UI=1 tests/ha/addon-test.sh <addon>`, which calls this.
#
# Playwright runs in a container inside the VM, on the HA network, built from
# the official image on first use. The script (ui-test.py) goes in on stdin
# and the screenshot comes back the same way: nothing is mounted.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
# shellcheck source=./common.sh
source tests/ha/common.sh

ADDON="${1:?usage: $0 <addon-directory> [screenshot.png]}"
SHOT="${2:-${TMPDIR:-/tmp}/ui-${ADDON}.png}"
CONTAINER="${HA_CONTAINER:-ha-supervisor}"

dock() { timeout -k 5 "${1}" docker "${@:2}"; }
in_vm() { dock "${1}" exec "${CONTAINER}" "${@:2}"; }

slug="$(sed -n 's/^slug:[[:space:]]*//p' "${ADDON}/config.yaml" | tr -d '"'"'")"
[ -n "${slug}" ] || {
    echo "no slug in ${ADDON}/config.yaml" >&2
    exit 1
}
expected="$(awk -v a="${ADDON}" '$1 == a { $1 = ""; sub(/^ +/, ""); print; exit }' tests/ha/ui-expected.txt)"
[ -n "${expected}" ] || {
    echo "no expected text for ${ADDON} in tests/ha/ui-expected.txt" >&2
    exit 1
}

if ! in_vm 30 docker image inspect "${PLAYWRIGHT_IMAGE}" >/dev/null 2>&1; then
    echo "building ${PLAYWRIGHT_IMAGE} inside the VM (first use only)" >&2
    printf 'FROM mcr.microsoft.com/playwright/python:v%s-noble\nRUN pip install --no-cache-dir --break-system-packages playwright==%s\n' \
        "${PLAYWRIGHT_VERSION}" "${PLAYWRIGHT_VERSION}" |
        dock 900 exec -i "${CONTAINER}" docker build -q -t "${PLAYWRIGHT_IMAGE}" - >/dev/null ||
        {
            echo "could not build ${PLAYWRIGHT_IMAGE}" >&2
            exit 1
        }
fi

result="$(dock 300 exec -i "${CONTAINER}" docker run -i --rm --network host "${PLAYWRIGHT_IMAGE}" \
    python - "local_${slug}" "${expected}" "${TEST_HA_USER}" "${TEST_HA_PASSWORD}" <tests/ha/ui-test.py | tail -1)"

if ! jq -e . >/dev/null 2>&1 <<<"${result}"; then
    echo "browser test produced no result" >&2
    exit 1
fi
jq -c 'del(.screenshot_png_b64)' <<<"${result}"
if ! jq -r '.screenshot_png_b64 // empty' <<<"${result}" | base64 -d >"${SHOT}" || [ ! -s "${SHOT}" ]; then
    echo "could not save the screenshot to ${SHOT}" >&2
    exit 1
fi
echo "screenshot: ${SHOT}"
jq -e '.ok' >/dev/null <<<"${result}"
