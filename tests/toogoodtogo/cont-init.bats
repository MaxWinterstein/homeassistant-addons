#!/usr/bin/env bats
#
# Unit tests for toogoodtogo-ha-mqtt-bridge/rootfs/etc/cont-init.d/
# toogoodtogo-ha-mqtt-bridge.sh — what it turns /data/options.json into.
#
# Home Assistant only supports two levels of nesting in an add-on's options, so
# config.yaml flattens intense_fetch into two sibling keys and the script folds
# them back with jq into the nested shape the bridge reads. That is exactly the
# kind of transform that breaks quietly: jq's += writes null for a missing key
# instead of failing, and the bridge starts anyway. (Ported from #583, which ran
# the same checks inside the built image.)
#
# The script hardcodes /data and /app. Rather than change the add-on, the test
# runs a copy with those two prefixes pointed into $TEST_ROOT; the jq logic
# under test is byte-for-byte the original.

setup() {
    load "../helpers/common.bash"
    load_bats_libs
    setup_addon_root

    export BASHIO_STUB="${HELPERS_DIR}/bashio.bash"
    export CONTENV="${HELPERS_DIR}/drivers/contenv.bash"
    ORIGINAL="${REPO_ROOT}/toogoodtogo-ha-mqtt-bridge/rootfs/etc/cont-init.d/toogoodtogo-ha-mqtt-bridge.sh"

    APP_DIR="${TEST_ROOT}/app/toogoodtogo_ha_mqtt_bridge"
    SETTINGS="${APP_DIR}/settings.local.json"
    mkdir -p "${APP_DIR}"

    SCRIPT="${TEST_ROOT}/cont-init.sh"
    sed -e "s#/data/#${TEST_ROOT}/data/#g" -e "s#/app/#${TEST_ROOT}/app/#g" \
        "${ORIGINAL}" >"${SCRIPT}"

    write_options <<'JSON'
{
  "mqtt": {
    "host": "mqtt-broker",
    "port": 1883,
    "username": "mqtt-user",
    "password": "mqtt-secret"
  },
  "tgtg": {
    "email": "tester@example.com",
    "language": "en-US",
    "polling_schedule": "*/10 * * * *",
    "intense_fetch_interval": 30,
    "intense_fetch_period_of_time": 5
  },
  "timezone": "Europe/Berlin",
  "locale": "en_us",
  "cleanup": true
}
JSON
}

run_cont_init() {
    BASH_ENV="${CONTENV}" run bash "${SCRIPT}"
}

setting() {
    jq -r "$1" "${SETTINGS}"
}

@test "the path redirection leaves no absolute /data or /app path behind" {
    # Guards the sed in setup(): if the script ever gains a path written
    # differently, this fails instead of the test touching the real /data.
    run grep -nE '(^|[^A-Za-z0-9_./-])/(data|app)(/|$)' "${SCRIPT}"
    assert_failure
}

@test "folds the flattened intense_fetch keys into the nested shape" {
    run_cont_init
    assert_success

    [ "$(setting '.tgtg.intense_fetch.interval')" = "30" ]
    [ "$(setting '.tgtg.intense_fetch.period_of_time')" = "5" ]
}

@test "keeps the flat keys and every other option untouched" {
    run_cont_init
    assert_success

    [ "$(setting '.tgtg.intense_fetch_interval')" = "30" ]
    [ "$(setting '.tgtg.intense_fetch_period_of_time')" = "5" ]
    [ "$(setting '.mqtt.host')" = "mqtt-broker" ]
    [ "$(setting '.mqtt.port')" = "1883" ]
    [ "$(setting '.mqtt.password')" = "mqtt-secret" ]
    [ "$(setting '.tgtg.email')" = "tester@example.com" ]
    [ "$(setting '.tgtg.polling_schedule')" = "*/10 * * * *" ]
    [ "$(setting '.timezone')" = "Europe/Berlin" ]
    [ "$(setting '.cleanup')" = "true" ]
}

@test "writes valid JSON and leaves no temp file behind" {
    run_cont_init
    assert_success

    jq . "${SETTINGS}" >/dev/null
    [ ! -e "${SETTINGS}.tmp" ]
}

@test "missing intense_fetch keys yield nulls, not an error" {
    # This is why DOCS.md has to keep listing them: the bridge would start with
    # a broken intense_fetch rather than failing loudly. Asserted so that if jq
    # ever starts erroring here instead, we find out on purpose.
    jq 'del(.tgtg.intense_fetch_interval, .tgtg.intense_fetch_period_of_time)' \
        "${HA_OPTIONS_FILE}" >"${HA_OPTIONS_FILE}.new"
    mv "${HA_OPTIONS_FILE}.new" "${HA_OPTIONS_FILE}"

    run_cont_init
    assert_success

    [ "$(setting '.tgtg.intense_fetch.interval')" = "null" ]
    [ "$(setting '.tgtg.intense_fetch.period_of_time')" = "null" ]
}

@test "asks for the email login when no tokens are saved" {
    run_cont_init
    assert_success
    assert_output --partial "No saved tokens found."
}

@test "recognises saved tokens" {
    echo '{}' >"${TEST_ROOT}/data/tokens.json"

    run_cont_init
    assert_success
    assert_output --partial "Saved tokens found."
    refute_output --partial "No saved tokens found."
}
