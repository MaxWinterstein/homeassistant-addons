#!/usr/bin/env bash
#
# Install an add-on from this repository into the real Home Assistant test
# instance, configure it, start it, and assert that it actually runs.
#
#   tests/ha/addon-test.sh planefence
#   KEEP=1 tests/ha/addon-test.sh planefence   # leave it installed afterwards
#
# This is the top of the pyramid — it exercises what nothing else does: the
# Supervisor parsing config.yaml, building the image from the local Dockerfile,
# the options round trip through the Supervisor API, ingress registration and
# the add-on running under s6 as a managed app.
#
# Requires the test instance to be up: tests/ha/supervisor-up.sh
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

ADDON="${1:-}"
[ -n "${ADDON}" ] || {
    echo "usage: $0 <addon-directory>" >&2
    exit 1
}
[ -d "${ADDON}" ] || {
    echo "no such add-on directory: ${ADDON}" >&2
    exit 1
}

CONTAINER="${HA_CONTAINER:-ha-supervisor}"
passed=0
failed=0

pass() {
    printf '\033[1;32m PASS \033[0m %s\n' "$*"
    passed=$((passed + 1))
}
fail() {
    printf '\033[1;31m FAIL \033[0m %s\n' "$*"
    failed=$((failed + 1))
}
info() { printf '\033[2m      %s\033[0m\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }

dock() { timeout -k 5 "${1}" docker "${@:2}"; }
in_vm() { dock "${1}" exec "${CONTAINER}" "${@:2}"; }
ha_cli() { dock "${1}" exec "${CONTAINER}" docker exec hassio_cli ha "${@:2}"; }

# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# The Supervisor REST API still uses /addons even though the CLI renamed the
# command to `apps`, so option updates go through curl rather than the CLI
# (which has no --options flag in this version).
sup_api() {
    local method="$1" path="$2" body="${3:-}"
    # The token has to expand inside the container, not here.
    # shellcheck disable=SC2016
    dock 90 exec "${CONTAINER}" docker exec hassio_cli sh -c "
    curl -sS -X ${method} \
      -H \"Authorization: Bearer \${SUPERVISOR_TOKEN}\" \
      -H 'Content-Type: application/json' \
      ${body:+-d '${body}'} \
      http://supervisor${path}
  "
}

# ── Preflight ───────────────────────────────────────────────────────────
step "Preflight"
if [ "$(dock 30 inspect -f '{{.State.Running}}' "${CONTAINER}" 2>/dev/null)" != "true" ]; then
    fail "${CONTAINER} is not running — start it with tests/ha/supervisor-up.sh"
    exit 1
fi
ha_cli 60 info >/dev/null 2>&1 || {
    fail "Supervisor is not answering"
    exit 1
}
pass "Home Assistant test instance is up"

SLUG="$(grep -m1 '^slug:' "${ADDON}/config.yaml" 2>/dev/null | awk '{print $2}')"
[ -n "${SLUG}" ] || SLUG="$(python3 -c "import json;print(json.load(open('${ADDON}/config.json'))['slug'])" 2>/dev/null)"
[ -n "${SLUG}" ] || {
    fail "could not read the slug from ${ADDON}"
    exit 1
}
APP="local_${SLUG}"
pass "add-on ${ADDON} -> ${APP}"

# ── Sync + force a local build ──────────────────────────────────────────
step "Sync this working tree into the VM"
if ./.orbstack/sync.sh >/dev/null 2>&1; then
    pass "workspace synced"
else
    fail "sync failed"
    exit 1
fi
# Re-running supervisor-up.sh can hide the workspace bind; repair it here so
# the install doesn't fail with "bind source path does not exist".
if in_vm 60 sh -c "${BIND_APPS_LOCAL}" >/dev/null 2>&1; then
    pass "workspace visible to the Supervisor"
else
    fail "could not make the workspace visible at /mnt/supervisor/apps/local/addons"
    exit 1
fi

# An add-on with `image:` set makes the Supervisor pull the published image,
# which would test the last release instead of the working tree. Comment it
# out in the VM's copy only — the repository is untouched.
step "Force a build from the local Dockerfile"
if in_vm 90 sh -c "sed -i 's|^image: |# image: |' /workspaces/addons/${ADDON}/config.yaml" 2>/dev/null; then
    pass "image: commented out in the VM copy"
else
    info "no image: line to comment out"
fi
ha_cli 120 store reload >/dev/null 2>&1

# ── Install ─────────────────────────────────────────────────────────────
step "Install through the Supervisor"
if ha_cli 60 apps info "${APP}" 2>/dev/null | grep -qE '^version: [^n]'; then
    info "already installed, reinstalling for a clean run"
    ha_cli 300 apps uninstall "${APP}" >/dev/null 2>&1
fi

if ha_cli 1800 apps install "${APP}" >/dev/null 2>&1; then
    pass "installed (Supervisor built the image from source)"
else
    fail "install failed"
    # The Supervisor logs "Build output:" and then swallows it, so dig the real
    # compiler/apt errors out of its log rather than leaving you guessing.
    info "build errors from the Supervisor log:"
    dock 60 logs "${CONTAINER}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' |
        grep -av 'DEBUG' |
        grep -aoE '(E: [^\\]{0,120}|Unable to locate package [a-z0-9.+-]+|exit code: [0-9]+)' |
        sort -u | head -6 | sed 's/^/      /'
    exit 1
fi

# ── Configure ───────────────────────────────────────────────────────────
step "Apply add-on options"
OPTIONS_FILE="${ADDON}/test/options.json"
if [ -f "${OPTIONS_FILE}" ]; then
    payload="{\"options\":$(tr -d '\n' <"${OPTIONS_FILE}")}"
    if sup_api POST "/addons/${APP}/options" "${payload}" 2>/dev/null | grep -q '"result":"ok"'; then
        pass "options applied from ${OPTIONS_FILE}"
    else
        fail "the Supervisor rejected the options — schema mismatch?"
    fi
else
    info "no ${OPTIONS_FILE}, using the config defaults"
fi

# ── Start ───────────────────────────────────────────────────────────────
step "Start the add-on"
# The start call can exceed the CLI's own HTTP timeout while s6 boots, so the
# state is what matters, not this exit code.
ha_cli 300 apps restart "${APP}" >/dev/null 2>&1
for _ in $(seq 1 30); do
    [ "$(ha_cli 60 apps info "${APP}" 2>/dev/null | awk '/^state:/{print $2}')" = "started" ] && break
    sleep 5
done

state="$(ha_cli 60 apps info "${APP}" 2>/dev/null | awk '/^state:/{print $2}')"
if [ "${state}" = "started" ]; then
    pass "Supervisor reports state=started"
else
    fail "state=${state:-unknown}"
    ha_cli 90 apps logs "${APP}" 2>&1 | tail -20
    exit 1
fi

# ── Assertions ──────────────────────────────────────────────────────────
step "Is it actually running?"
sleep 10
read -r status health restarts <<<"$(
    in_vm 60 docker inspect "app_${APP}" \
        --format '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}} {{.RestartCount}}' 2>/dev/null
)"
if [ "${status}" = "running" ]; then
    pass "container running"
else
    fail "container status=${status:-missing}"
fi
case "${health}" in
healthy | n/a) pass "health=${health}" ;;
*) fail "health=${health}" ;;
esac
if [ "${restarts}" = "0" ]; then
    pass "no restarts"
else
    fail "restarted ${restarts} time(s) — crash loop?"
fi

step "Add-on logs"
logs="$(ha_cli 90 apps logs "${APP}" 2>&1)"
if grep -qiE 's6-overlay-suexec: fatal|did not signal ready' <<<"${logs}"; then
    fail "fatal errors in the add-on log"
    grep -iE 's6-overlay-suexec: fatal|did not signal ready' <<<"${logs}" | head -3
else
    pass "no fatal errors"
fi

step "Web UI"
port="$(grep -m1 '^ingress_port:' <(ha_cli 60 apps info "${APP}" 2>/dev/null) | awk '{print $2}')"
# `ha apps info` prints "ingress_port: null" for add-ons without ingress.
if [[ "${port}" =~ ^[1-9][0-9]*$ ]]; then
    # Probe the way ingress does: from the Supervisor (172.30.32.2 on the
    # hassio network). Add-ons commonly allow only that address in their web
    # server, so a request from 127.0.0.1 inside the add-on gets a 403.
    # host_network add-ons have no hassio address; the Supervisor reaches them
    # via the gateway, 172.30.32.1.
    addr="$(in_vm 60 docker inspect "app_${APP}" \
        --format '{{with index .NetworkSettings.Networks "hassio"}}{{.IPAddress}}{{end}}' 2>/dev/null)"
    addr="${addr:-172.30.32.1}"
    # Ask for the page HA opens in the sidebar (ingress_entry), not just "/".
    entry="$(sed -n 's/^ingress_entry:[[:space:]]*//p' "${ADDON}/config.yaml" | tr -d '"'"'"'')"
    url="http://${addr}:${port}/${entry#/}"
    code="$(in_vm 90 docker exec hassio_supervisor \
        curl -sS -o /dev/null -w '%{http_code}' "${url}" 2>/dev/null)"
    if [[ "${code}" =~ ^[23][0-9][0-9]$ ]]; then
        pass "add-on answers ingress requests (${url} -> HTTP ${code})"
    else
        fail "ingress ${url} returned '${code}'"
    fi
else
    info "add-on has no ingress, skipping"
fi

# ── Teardown ────────────────────────────────────────────────────────────
if [ "${KEEP:-0}" = "1" ]; then
    info "KEEP=1: leaving ${APP} installed and running"
else
    step "Cleanup"
    ha_cli 300 apps uninstall "${APP}" >/dev/null 2>&1 && info "uninstalled ${APP}"
fi

step "Summary"
printf '%d passed, %d failed\n' "${passed}" "${failed}"
[ "${failed}" -eq 0 ]
