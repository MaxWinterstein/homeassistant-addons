#!/usr/bin/env bash
# Runs the add-on's cont-init script inside the built image and checks what it
# turns /data/options.json into.
#
# Home Assistant only supports two levels of nesting in an add-on's options, so
# the script flattens intense_fetch into two sibling keys in config.yaml and jq
# folds them back into the nested shape the bridge expects. Nothing tested that
# until now, and it is exactly the kind of transform that breaks quietly: a jq
# typo yields nulls rather than an error, and the bridge starts anyway.
#
# Usage: cont-init.test.sh <image-tag>
set -euo pipefail

IMAGE="${1:?usage: cont-init.test.sh <image-tag>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT=/etc/cont-init.d/toogoodtogo-ha-mqtt-bridge.sh
SETTINGS=/app/toogoodtogo_ha_mqtt_bridge/settings.local.json

fail() {
  echo "::error::$*"
  exit 1
}

# The script's shebang is `#!/usr/bin/with-contenv bashio`, which needs s6's
# container_environment directory. Invoking bashio as the interpreter runs the
# script with the library sourced and skips that dependency: bashio's runner is
# `BASH_ARGV0=${1:?}; shift; source "$0" "$@"`.
run_cont_init() {
  local options_file="$1"
  docker run --rm \
    -v "${options_file}:/data/options.json:ro" \
    --entrypoint /bin/bash \
    "${IMAGE}" -c \
    "/usr/bin/bashio ${SCRIPT} >&2 && cat ${SETTINGS}"
}

echo "--- a complete config is folded into the nested shape the bridge reads"
settings="$(run_cont_init "${HERE}/options.json")" ||
  fail "cont-init failed on a valid options.json"

echo "${settings}" | jq . >/dev/null || fail "cont-init produced invalid JSON"

check() {
  local filter="$1" want="$2" got
  got="$(echo "${settings}" | jq -r "${filter}")"
  [[ "${got}" == "${want}" ]] || fail "${filter}: expected '${want}', got '${got}'"
  echo "    ok  ${filter} = ${got}"
}

# The flattening is the part under test.
check '.tgtg.intense_fetch.interval' '30'
check '.tgtg.intense_fetch_interval' '30'
check '.tgtg.intense_fetch.period_of_time' '5'
check '.tgtg.intense_fetch_period_of_time' '5'

# Everything else must survive the copy untouched.
check '.mqtt.host' 'mqtt-broker'
check '.mqtt.port' '1883'
check '.tgtg.email' 'tester@example.com'
check '.tgtg.polling_schedule' '*/10 * * * *'
check '.timezone' 'Europe/Berlin'
check '.cleanup' 'true'

echo "--- an options.json missing the intense_fetch keys yields nulls, not an error"
# This is why DOCS.md has to keep listing them. jq's += happily writes null for
# a key that is not there, so the bridge would start with a broken intense_fetch
# rather than failing loudly. Asserted so that if jq ever starts erroring here
# instead, we find out on purpose rather than in an issue report.
partial="$(mktemp)"
trap 'rm -f "${partial}"' EXIT
jq 'del(.tgtg.intense_fetch_interval, .tgtg.intense_fetch_period_of_time)' \
  "${HERE}/options.json" >"${partial}"

partial_settings="$(run_cont_init "${partial}")" ||
  fail "cont-init should not crash on a config missing intense_fetch keys"

got="$(echo "${partial_settings}" | jq -r '.tgtg.intense_fetch.interval')"
[[ "${got}" == "null" ]] ||
  fail ".tgtg.intense_fetch.interval: expected 'null' for a partial config, got '${got}'"
echo "    ok  missing keys produce null, silently, as documented"

echo "--- all assertions passed"
