#!/usr/bin/env bats
#
# Unit tests for planefence/export-env-from-config.sh — the script that turns
# the add-on's options.json into environment variables and resolves the
# HOMEASSISTANT_* placeholders against the HA Core API.
#
# No Docker and no Home Assistant: bashio, curl and sleep are stubbed, and the
# options file lives in a temp directory.

setup() {
    load "../helpers/common.bash"
    load_bats_libs
    setup_addon_root
    stub_sleep

    export BASHIO_STUB="${HELPERS_DIR}/bashio.bash"
    # Overridable so the suite can be pointed at a deliberately mutated copy of
    # the script, to check that these tests actually fail when the behaviour
    # they describe breaks.
    export EXPORT_ENV_SCRIPT="${EXPORT_ENV_SCRIPT:-${REPO_ROOT}/planefence/export-env-from-config.sh}"
    export DRIVER="${HELPERS_DIR}/drivers/source-export-env.sh"
    export SUPERVISOR_TOKEN="test-token"
}

# Value of one exported variable, read out of the driver's env dump.
exported() {
    echo "${output}" | sed -n '/^---ENV---$/,$p' | grep -m1 "^${1}=" | cut -d= -f2-
}

# ── Reading options ─────────────────────────────────────────────────────

@test "exports every option from options.json as an environment variable" {
    write_options <<'JSON'
{
  "PF_SOCK30003HOST": "192.168.1.125",
  "PF_SOCK30003PORT": 30003,
  "PF_LAT": "50.0379",
  "TZ": "Europe/Berlin"
}
JSON

    run bash "${DRIVER}"
    assert_success
    [ "$(exported PF_SOCK30003HOST)" = "192.168.1.125" ]
    [ "$(exported PF_SOCK30003PORT)" = "30003" ]
    [ "$(exported PF_LAT)" = "50.0379" ]
    [ "$(exported TZ)" = "Europe/Berlin" ]
}

@test "fails with a clear error when options.json is missing" {
    rm -f "${HA_OPTIONS_FILE}"

    run bash "${DRIVER}"
    assert_failure
    assert_output --partial "not found"
}

@test "preserves values containing spaces" {
    write_options <<'JSON'
{ "PF_NAME": "My Plane Fence", "PF_MOTD": "hello world  two spaces" }
JSON

    run bash "${DRIVER}"
    assert_success
    [ "$(exported PF_NAME)" = "My Plane Fence" ]
    [ "$(exported PF_MOTD)" = "hello world  two spaces" ]
}

@test "handles an empty options object without failing" {
    write_options <<<'{}'

    run bash "${DRIVER}"
    assert_success
    assert_output --partial "Done."
}

# ── Placeholder resolution ──────────────────────────────────────────────

@test "does not call the Supervisor API when there are no placeholders" {
    write_options <<'JSON'
{ "PF_LAT": "50.0379", "PF_LON": "8.5622" }
JSON
    stub_curl_success '{"latitude":1.0,"longitude":2.0,"time_zone":"UTC"}'

    run bash "${DRIVER}"
    assert_success
    assert_output --partial "No HOMEASSISTANT_* placeholders found"
    [ "$(curl_call_count)" = "0" ]
}

@test "replaces latitude, longitude and timezone placeholders from the API" {
    write_options <<'JSON'
{
  "PF_LAT": "HOMEASSISTANT_LATITUDE",
  "PF_LON": "HOMEASSISTANT_LONGITUDE",
  "TZ": "HOMEASSISTANT_TIMEZONE"
}
JSON
    stub_curl_success '{"latitude":50.1234,"longitude":8.5678,"time_zone":"Europe/Berlin"}'

    run bash "${DRIVER}"
    assert_success
    [ "$(exported PF_LAT)" = "50.1234" ]
    [ "$(exported PF_LON)" = "8.5678" ]
    [ "$(exported TZ)" = "Europe/Berlin" ]
}

@test "replaces a placeholder embedded in a larger string" {
    write_options <<'JSON'
{ "PF_MOTD": "station at HOMEASSISTANT_LATITUDE degrees" }
JSON
    stub_curl_success '{"latitude":50.1234,"longitude":8.5678,"time_zone":"Europe/Berlin"}'

    run bash "${DRIVER}"
    assert_success
    [ "$(exported PF_MOTD)" = "station at 50.1234 degrees" ]
}

@test "keeps placeholders unresolved and warns when the API never answers" {
    write_options <<'JSON'
{ "PF_LAT": "HOMEASSISTANT_LATITUDE", "PF_LON": "HOMEASSISTANT_LONGITUDE" }
JSON
    stub_curl_failure

    run bash "${DRIVER}"
    assert_success
    assert_output --partial "Could not resolve HA location/timezone"
    [ "$(exported PF_LAT)" = "HOMEASSISTANT_LATITUDE" ]
    [ "$(exported PF_LON)" = "HOMEASSISTANT_LONGITUDE" ]
}

@test "retries the API the documented number of times before giving up" {
    write_options <<'JSON'
{ "PF_LAT": "HOMEASSISTANT_LATITUDE" }
JSON
    stub_curl_failure

    run bash "${DRIVER}"
    assert_success
    # The script documents 10 attempts.
    [ "$(curl_call_count)" = "10" ]
}

@test "keeps placeholders when the API answers but omits the fields" {
    write_options <<'JSON'
{ "PF_LAT": "HOMEASSISTANT_LATITUDE", "TZ": "HOMEASSISTANT_TIMEZONE" }
JSON
    stub_curl_success '{"unrelated":true}'

    run bash "${DRIVER}"
    assert_success
    assert_output --partial "some values empty in response"
    [ "$(exported PF_LAT)" = "HOMEASSISTANT_LATITUDE" ]
    [ "$(exported TZ)" = "HOMEASSISTANT_TIMEZONE" ]
}

@test "warns when SUPERVISOR_TOKEN is absent but still attempts resolution" {
    write_options <<'JSON'
{ "PF_LAT": "HOMEASSISTANT_LATITUDE" }
JSON
    stub_curl_success '{"latitude":50.1,"longitude":8.5,"time_zone":"UTC"}'
    unset SUPERVISOR_TOKEN

    run bash "${DRIVER}"
    assert_success
    assert_output --partial "SUPERVISOR_TOKEN is not set"
    [ "$(exported PF_LAT)" = "50.1" ]
}

# ── Re-sourcing guard ───────────────────────────────────────────────────

@test "is a no-op when already sourced in the same process" {
    write_options <<'JSON'
{ "PF_LAT": "50.0379" }
JSON

    run env _HA_CONFIG_EXPORTED=1 bash "${DRIVER}"
    assert_success
    refute_output --partial "Exporting options from"
}
