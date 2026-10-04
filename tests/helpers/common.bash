#!/usr/bin/env bash
#
# Shared bats setup for the add-on shell tests.
#
# These tests are deliberately Docker-free: they run the real cont-init
# scripts against a temporary directory tree, with `bashio` and `curl` stubbed
# out. That keeps the inner loop at roughly a second, which is the whole point
# of testing config translation at this level rather than by booting Home
# Assistant.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
HELPERS_DIR="${REPO_ROOT}/tests/helpers"
export HELPERS_DIR

# Load bats helper libraries. BATS_LIB_PATH is set by the sandbox image; fall
# back to the usual Debian location so the tests also run on a plain box.
load_bats_libs() {
    export BATS_LIB_PATH="${BATS_LIB_PATH:-/usr/lib/bats}"
    bats_load_library bats-support
    bats_load_library bats-assert
}

# Create an isolated fake add-on filesystem for one test.
#
# Everything the scripts touch lives under $TEST_ROOT, which is passed to them
# as HA_ROOT. In production HA_ROOT is unset, so the same code uses the real
# absolute paths.
setup_addon_root() {
    TEST_ROOT="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/addon-root.XXXXXX")"
    export TEST_ROOT
    export HA_ROOT="${TEST_ROOT}"

    mkdir -p "${TEST_ROOT}/data" "${TEST_ROOT}/run" "${TEST_ROOT}/usr/share"

    STUB_BIN="${TEST_ROOT}/stub-bin"
    mkdir -p "${STUB_BIN}"
    export STUB_BIN
    export PATH="${STUB_BIN}:${PATH}"

    export HA_OPTIONS_FILE="${TEST_ROOT}/data/options.json"
}

# Write the add-on options file the scripts read.
write_options() {
    mkdir -p "$(dirname "${HA_OPTIONS_FILE}")"
    cat >"${HA_OPTIONS_FILE}"
}

# Stub `curl` so the Supervisor API call returns a chosen payload.
# Usage: stub_curl_success '{"latitude":1.0,...}'
stub_curl_success() {
    local payload="$1"
    cat >"${STUB_BIN}/curl" <<EOF
#!/usr/bin/env bash
# Records that it was called, so tests can assert the API was (not) consulted.
echo "curl \$*" >> "${TEST_ROOT}/curl.calls"
cat <<'PAYLOAD'
${payload}
PAYLOAD
exit 0
EOF
    chmod +x "${STUB_BIN}/curl"
}

# Stub `curl` so the Supervisor API call always fails, as it does when Home
# Assistant Core is not up yet.
stub_curl_failure() {
    cat >"${STUB_BIN}/curl" <<EOF
#!/usr/bin/env bash
echo "curl \$*" >> "${TEST_ROOT}/curl.calls"
echo "curl: (7) Failed to connect to supervisor port 80" >&2
exit 7
EOF
    chmod +x "${STUB_BIN}/curl"
}

# Stub `sleep` to a no-op, so retry loops do not make the suite slow.
stub_sleep() {
    printf '#!/usr/bin/env bash\nexit 0\n' >"${STUB_BIN}/sleep"
    chmod +x "${STUB_BIN}/sleep"
}

# How many times the curl stub was invoked.
curl_call_count() {
    if [ -f "${TEST_ROOT}/curl.calls" ]; then
        wc -l <"${TEST_ROOT}/curl.calls" | tr -d ' '
    else
        echo 0
    fi
}
