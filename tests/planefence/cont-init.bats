#!/usr/bin/env bats
#
# Unit tests for planefence/rootfs/etc/cont-init.d/00-ha-planefence-config.sh —
# the script that translates the add-on's options into planefence.config.
#
# This is where the bugs live: it is ~280 lines of bash whose whole job is
# careful config merging, and its own comments document a v0.1.3 regression
# that wiped upstream template defaults and put the add-on into a restart loop.
# Those behaviours are pinned down here.

setup() {
    load "../helpers/common.bash"
    load_bats_libs
    setup_addon_root

    export BASHIO_STUB="${HELPERS_DIR}/bashio.bash"
    export CONTENV="${HELPERS_DIR}/drivers/contenv.bash"
    export SCRIPT="${SCRIPT:-${REPO_ROOT}/planefence/rootfs/etc/cont-init.d/00-ha-planefence-config.sh}"

    build_planefence_root
}

# Build the parts of the container filesystem the script expects to find.
build_planefence_root() {
    mkdir -p \
        "${TEST_ROOT}/usr/share/planefence" \
        "${TEST_ROOT}/usr/share/zoneinfo/Europe" \
        "${TEST_ROOT}/var/lib/planefence-persist" \
        "${TEST_ROOT}/run" \
        "${TEST_ROOT}/etc"

    touch "${TEST_ROOT}/usr/share/zoneinfo/Europe/Berlin"

    # The Dockerfile copies this next to the cont-init script in production.
    cp "${REPO_ROOT}/planefence/export-env-from-config.sh" \
        "${TEST_ROOT}/export-env-from-config.sh"

    # Point export-env at our fake options file.
    export HA_OPTIONS_FILE="${TEST_ROOT}/data/options.json"
}

# Use /addon_configs as the persistence target (the modern HA mapping).
use_addon_configs() {
    mkdir -p "${TEST_ROOT}/addon_configs"
}

# Install an upstream-style template with defaults the add-on must not clobber.
write_template() {
    cat >"${TEST_ROOT}/planefence.config.template"
}

run_cont_init() {
    run env BASH_ENV="${CONTENV}" bash "${SCRIPT}"
}

# Path to the generated config for the /addon_configs layout.
config_file() { echo "${TEST_ROOT}/addon_configs/planefence/planefence.config"; }

# Value of a key in the generated config.
config_value() {
    grep -m1 "^${1}=" "$(config_file)" | cut -d= -f2-
}

# ── Where persistent data goes ──────────────────────────────────────────

@test "prefers /addon_configs when the modern mapping is present" {
    use_addon_configs
    mkdir -p "${TEST_ROOT}/config"
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'

    run_cont_init
    assert_success
    assert_output --partial "Using ${TEST_ROOT}/addon_configs/planefence"
    [ -f "$(config_file)" ]
}

@test "falls back to /config when /addon_configs is absent" {
    mkdir -p "${TEST_ROOT}/config"
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'

    run_cont_init
    assert_success
    assert_output --partial "Using ${TEST_ROOT}/config/planefence"
    [ -f "${TEST_ROOT}/config/planefence/planefence.config" ]
}

@test "falls back to the ephemeral stub when no mount exists at all" {
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'

    run_cont_init
    assert_success
    assert_output --partial "no persistent mount found"
    [ -f "${TEST_ROOT}/var/lib/planefence-persist/planefence.config" ]
}

@test "points the persist symlink at the resolved location" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'

    run_cont_init
    assert_success
    [ "$(readlink "${TEST_ROOT}/usr/share/planefence/persist")" = "${TEST_ROOT}/addon_configs/planefence" ]
}

# ── First start ─────────────────────────────────────────────────────────

@test "copies the upstream template for the user to edit on first start" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'
    write_template <<'EOF'
PF_INTERVAL=80
EOF

    run_cont_init
    assert_success
    [ -f "${TEST_ROOT}/addon_configs/planefence/planefence.config.RENAME-and-EDIT-me" ]
}

@test "seeds planefence.config from the template on first start" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'
    write_template <<'EOF'
PF_INTERVAL=80
PF_ALERTLIST=/usr/share/planefence/persist/plane-alert-db.txt
EOF

    run_cont_init
    assert_success
    [ "$(config_value PF_INTERVAL)" = "80" ]
}

@test "creates the alert database files that upstream scripts require" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'

    run_cont_init
    assert_success
    [ -f "${TEST_ROOT}/addon_configs/planefence/plane-alert-db.txt" ]
    [ -f "${TEST_ROOT}/addon_configs/planefence/.internal/plane-alert-db.txt" ]
}

# ── The v0.1.3 regression ───────────────────────────────────────────────

@test "REGRESSION v0.1.3: an empty option must not wipe the template default" {
    use_addon_configs
    # PF_INTERVAL is deliberately absent from the options; the upstream default
    # in the template has to survive. v0.1.3 unset it and broke the add-on.
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5","PF_INTERVAL":""}'
    write_template <<'EOF'
PF_INTERVAL=80
PF_ALERTLIST=/usr/share/planefence/persist/plane-alert-db.txt
EOF

    run_cont_init
    assert_success
    [ "$(config_value PF_INTERVAL)" = "80" ]
}

@test "REGRESSION v0.1.3: PF_ALERTLIST default survives an empty option" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5","PF_ALERTLIST":""}'
    write_template <<'EOF'
PF_ALERTLIST=/usr/share/planefence/persist/plane-alert-db.txt
EOF

    run_cont_init
    assert_success
    [ "$(config_value PF_ALERTLIST)" = "/usr/share/planefence/persist/plane-alert-db.txt" ]
}

@test "migration restores PF_ALERTLIST when a v0.1.3 config already lost it" {
    use_addon_configs
    mkdir -p "${TEST_ROOT}/addon_configs/planefence"
    # A config damaged by v0.1.3: PF_ALERTLIST is gone.
    cat >"$(config_file)" <<'EOF'
PF_INTERVAL=80
EOF
    cat >"${TEST_ROOT}/addon_configs/planefence/planefence.config.RENAME-and-EDIT-me" <<'EOF'
PF_ALERTLIST=/usr/share/planefence/persist/plane-alert-db.txt
EOF
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'

    run_cont_init
    assert_success
    assert_output --partial "Restored missing PF_ALERTLIST"
    [ "$(config_value PF_ALERTLIST)" = "/usr/share/planefence/persist/plane-alert-db.txt" ]
}

# ── set_config behaviour ────────────────────────────────────────────────

@test "a non-empty option overrides the template default" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5","PF_INTERVAL":"120"}'
    write_template <<'EOF'
PF_INTERVAL=80
EOF

    run_cont_init
    assert_success
    [ "$(config_value PF_INTERVAL)" = "120" ]
}

@test "updates a key in place rather than appending a duplicate" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"51.5","PF_LON":"8.5"}'
    write_template <<'EOF'
FEEDER_LAT=1.0
EOF

    run_cont_init
    assert_success
    [ "$(grep -c '^FEEDER_LAT=' "$(config_file)")" = "1" ]
    [ "$(config_value FEEDER_LAT)" = "51.5" ]
}

@test "escapes sed-special characters when rewriting an existing key" {
    use_addon_configs
    write_options <<'JSON'
{
  "PF_LAT": "50.0",
  "PF_LON": "8.5",
  "PF_MOTD": "a&b/c|d\\e"
}
JSON
    # The key must already be present, otherwise set_config appends instead of
    # running the sed substitution — and the escaping is never exercised.
    write_template <<'EOF'
PF_MOTD=placeholder
EOF

    run_cont_init
    assert_success
    [ "$(config_value PF_MOTD)" = 'a&b/c|d\e' ]
    [ "$(grep -c '^PF_MOTD=' "$(config_file)")" = "1" ]
}

@test "writes the required station keys from the add-on options" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0379","PF_LON":"8.5622","PF_MAXDIST":"3.5","PF_MAXALT":"7000"}'

    run_cont_init
    assert_success
    [ "$(config_value FEEDER_LAT)" = "50.0379" ]
    [ "$(config_value FEEDER_LONG)" = "8.5622" ]
    [ "$(config_value PF_MAXDIST)" = "3.5" ]
    [ "$(config_value PF_MAXALT)" = "7000" ]
}

@test "defaults the feeder host to the ADS-B add-on hostname" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'

    run_cont_init
    assert_success
    [ "$(config_value PF_SOCK30003HOST)" = "f1c878cb-adsb-multi-portal-feeder" ]
    [ "$(config_value PF_SOCK30003PORT)" = "30003" ]
}

@test "honours an explicit feeder host and port" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5","PF_SOCK30003HOST":"192.168.1.125","PF_SOCK30003PORT":"31003"}'

    run_cont_init
    assert_success
    [ "$(config_value PF_SOCK30003HOST)" = "192.168.1.125" ]
    [ "$(config_value PF_SOCK30003PORT)" = "31003" ]
}

# ── Timezone and readiness ──────────────────────────────────────────────

@test "applies the timezone when the zoneinfo file exists" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5","TZ":"Europe/Berlin"}'

    run_cont_init
    assert_success
    [ "$(cat "${TEST_ROOT}/etc/timezone")" = "Europe/Berlin" ]
    [ "$(readlink "${TEST_ROOT}/etc/localtime")" = "${TEST_ROOT}/usr/share/zoneinfo/Europe/Berlin" ]
}

@test "signals readiness so the patched s6 service may proceed" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'

    run_cont_init
    assert_success
    [ -f "${TEST_ROOT}/run/ha-planefence-ready" ]
}

@test "warns when the location placeholders were never resolved" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"HOMEASSISTANT_LATITUDE","PF_LON":"HOMEASSISTANT_LONGITUDE"}'
    stub_curl_failure
    stub_sleep

    run_cont_init
    assert_success
    assert_output --partial "PF_LAT/PF_LON are still placeholders"
}

# ── Upstream template renames (docker-planefence latest-build-1249+) ────
#
# The assertions source the generated config the way upstream's
# prep-planefence.sh does (set -o allexport) and evaluate upstream's own
# expressions, so they check what Planefence actually sees.

# Upstream's effective value of an expression after sourcing the config.
upstream_sees() {
    (
        set -o allexport
        # shellcheck source=/dev/null
        . "$(config_file)"
        eval "printf '%s' \"$1\""
    )
}

@test "fresh install on a FEEDER_LON template gets the real longitude (upstream 1249+)" {
    # 1249 renamed FEEDER_LONG to FEEDER_LON and checks ${FEEDER_LON:-$FEEDER_LONG}.
    # Writing only FEEDER_LONG left the template's -70.12345 in FEEDER_LON, so
    # upstream reported "SETUP REQUIRED" on every fresh install.
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.12","PF_LON":"8.68"}'
    write_template <<'EOF'
FEEDER_LAT=90.12345
FEEDER_LON=-70.12345
EOF

    run_cont_init
    assert_success
    [ "$(upstream_sees '$FEEDER_LAT')" = "50.12" ]
    [ "$(upstream_sees '${FEEDER_LON:-$FEEDER_LONG}')" = "8.68" ]
}

@test "an older FEEDER_LONG template still gets the real longitude" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.12","PF_LON":"8.68"}'
    write_template <<'EOF'
FEEDER_LAT=90.12345
FEEDER_LONG=-70.12345
EOF

    run_cont_init
    assert_success
    [ "$(upstream_sees '${FEEDER_LON:-$FEEDER_LONG}')" = "8.68" ]
    [ "$(config_value FEEDER_LONG)" = "8.68" ]
}

@test "PF_PLANEALERT=OFF beats the template's PLANEALERT=ON (upstream 1249+)" {
    # Upstream reads ${PLANEALERT:-$PF_PLANEALERT}; the new template sets
    # PLANEALERT=ON, which would win over the add-on option.
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5","PF_PLANEALERT":"OFF"}'
    write_template <<'EOF'
PLANEALERT=ON
EOF

    run_cont_init
    assert_success
    [ "$(upstream_sees '${PLANEALERT:-$PF_PLANEALERT}')" = "OFF" ]
}

@test "without PF_PLANEALERT the template's PLANEALERT default is kept" {
    use_addon_configs
    write_options <<<'{"PF_LAT":"50.0","PF_LON":"8.5"}'
    write_template <<'EOF'
PLANEALERT=ON
EOF

    run_cont_init
    assert_success
    [ "$(upstream_sees '${PLANEALERT:-$PF_PLANEALERT}')" = "ON" ]
}
