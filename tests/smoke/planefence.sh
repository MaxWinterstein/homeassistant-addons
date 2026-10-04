#!/usr/bin/env bash
#
# Container smoke test for the planefence add-on: build the real image, start
# it with a fake Supervisor environment, and assert it comes up correctly.
#
# This is the layer above the bats unit tests. Those check the config
# translation in isolation in about a second; this one proves the whole add-on
# actually boots — the s6 patches, the /run/ha-planefence-ready handshake and
# the web UI included.
#
# Needs a Docker daemon. There is deliberately no daemon in the Claude sandbox,
# so DOCKER_HOST should point at the OrbStack VM (see .orbstack/README.md).
#
#   tests/smoke/planefence.sh
#   KEEP=1 tests/smoke/planefence.sh    # leave the container running to poke at
#
# Fixture data is passed through a named volume rather than a bind mount,
# because bind mounts resolve on the *daemon* host — which is a different
# machine from the one running this script.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

# Overridable so this suite can be pointed at a deliberately mutated copy of
# the add-on, to confirm it really fails when the add-on breaks.
ADDON_DIR="${ADDON_DIR:-./planefence}"
IMAGE="planefence-smoke:local"
CONTAINER="planefence-smoke"
VOL_DATA="planefence-smoke-data"
VOL_CONFIG="planefence-smoke-config"
PORT="${PORT:-8099}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-150}"

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

# docker run forwards SIGTERM to the container instead of exiting, so a plain
# timeout cannot kill it — -k escalates to SIGKILL. See .orbstack/README.md.
dock() { timeout -k 5 "${1}" docker "${@:2}"; }

cleanup() {
    [ "${KEEP:-0}" = "1" ] && {
        info "KEEP=1, leaving ${CONTAINER} running on port ${PORT}"
        return
    }
    dock 60 rm -f "${CONTAINER}" >/dev/null 2>&1
    dock 60 volume rm -f "${VOL_DATA}" "${VOL_CONFIG}" >/dev/null 2>&1
}
trap cleanup EXIT

# Hostname to reach published ports on: the daemon's host, not ours.
daemon_host() {
    case "${DOCKER_HOST:-}" in
    tcp://* | ssh://*)
        local hostport="${DOCKER_HOST#*://}"
        echo "${hostport%%:*}"
        ;;
    *) echo "localhost" ;;
    esac
}

# ── Preflight ───────────────────────────────────────────────────────────
step "Preflight"
command -v docker >/dev/null 2>&1 || {
    fail "no docker client (run .orbstack/sandbox-setup.sh)"
    exit 1
}
if ! dock 30 version --format '{{.Server.Version}}' >/dev/null 2>&1; then
    fail "cannot reach a Docker daemon at ${DOCKER_HOST:-the local socket}"
    info "diagnose with: .orbstack/doctor.sh"
    exit 1
fi
HOST="$(daemon_host)"
pass "daemon reachable, publishing to ${HOST}:${PORT}"

# ── Build ───────────────────────────────────────────────────────────────
step "Build the add-on image"
if dock 900 build -q -t "${IMAGE}" "${ADDON_DIR}" >/dev/null 2>&1; then
    pass "image built"
else
    fail "build failed"
    dock 900 build -t "${IMAGE}" "${ADDON_DIR}" 2>&1 | tail -20
    exit 1
fi

# ── Fixture ─────────────────────────────────────────────────────────────
step "Seed the Supervisor fixture"
cleanup 2>/dev/null
dock 60 volume create "${VOL_DATA}" >/dev/null
dock 60 volume create "${VOL_CONFIG}" >/dev/null
if tar -C "${ADDON_DIR}/test" -cf - options.json |
    dock 90 run -i --rm -v "${VOL_DATA}:/dest" alpine:3 \
        sh -c 'tar x -C /dest && mv /dest/options.json /dest/options.json' >/dev/null 2>&1; then
    pass "options.json placed in /data"
else
    fail "could not seed the fixture volume"
    exit 1
fi

# ── Run ─────────────────────────────────────────────────────────────────
step "Start the add-on"
if dock 120 run -d --name "${CONTAINER}" \
    -v "${VOL_DATA}:/data" \
    -v "${VOL_CONFIG}:/addon_configs/planefence" \
    -e SUPERVISOR_TOKEN=fake \
    -p "${PORT}:80" \
    "${IMAGE}" >/dev/null 2>&1; then
    pass "container started"
else
    fail "container would not start"
    exit 1
fi

step "Wait for boot"
booted=0
for _ in $(seq 1 "${BOOT_TIMEOUT}"); do
    health="$(dock 30 inspect "${CONTAINER}" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' 2>/dev/null)"
    running="$(dock 30 inspect "${CONTAINER}" --format '{{.State.Running}}' 2>/dev/null)"
    [ "${running}" = "false" ] && break
    if [ "${health}" = "healthy" ]; then
        booted=1
        break
    fi
    # Images without a HEALTHCHECK: settle for the readiness handshake.
    if [ "${health}" = "none" ] &&
        dock 30 exec "${CONTAINER}" test -f /run/ha-planefence-ready >/dev/null 2>&1; then
        booted=1
        break
    fi
    sleep 1
done

if [ "${booted}" = "1" ]; then
    pass "add-on booted"
else
    fail "add-on did not become ready within ${BOOT_TIMEOUT}s"
    dock 60 logs "${CONTAINER}" 2>&1 | tail -30
    exit 1
fi

# ── Assertions ──────────────────────────────────────────────────────────
step "Config translation"
CONFIG=/usr/share/planefence/persist/planefence.config

cfg() {
    dock 30 exec "${CONTAINER}" sh -c "grep -m1 '^${1}=' ${CONFIG} 2>/dev/null | cut -d= -f2-" 2>/dev/null | tr -d '\r\n'
}

check() {
    local key="$1" want="$2" got
    got="$(cfg "${key}")"
    if [ "${got}" = "${want}" ]; then
        pass "${key}=${got}"
    else
        fail "${key}: expected '${want}', got '${got}'"
    fi
}

# Values that must come from options.json.
check FEEDER_LAT 50.0379
check FEEDER_LONG 8.5622
check PF_SOCK30003HOST 192.168.1.125
check PF_SOCK30003PORT 30003
check PF_MAXDIST 2.0
check PF_MAXALT 5000
check TZ Europe/Berlin

step "Upstream template defaults survive (v0.1.3 regression)"
# Neither key is in options.json, so both must still hold the upstream
# template's value. v0.1.3 blanked them and put the add-on in a restart loop.
for key in PF_INTERVAL PF_ALERTLIST; do
    value="$(cfg "${key}")"
    if [ -n "${value}" ]; then
        pass "${key} kept its template default (${value:0:48})"
    else
        fail "${key} is empty — the v0.1.3 regression is back"
    fi
done

step "Container plumbing"
if dock 30 exec "${CONTAINER}" test -f /run/ha-planefence-ready >/dev/null 2>&1; then
    pass "readiness handshake file present"
else
    fail "/run/ha-planefence-ready missing — patched s6 scripts would stall"
fi

link="$(dock 30 exec "${CONTAINER}" readlink /usr/share/planefence/persist 2>/dev/null | tr -d '\r\n')"
if [ "${link}" = "/addon_configs/planefence" ]; then
    pass "persist symlink -> ${link}"
else
    fail "persist symlink points at '${link}', expected /addon_configs/planefence"
fi

restarts="$(dock 30 inspect "${CONTAINER}" --format '{{.RestartCount}}' 2>/dev/null)"
if [ "${restarts}" = "0" ]; then
    pass "no restarts"
else
    fail "container restarted ${restarts} time(s) — likely a crash loop"
fi

step "Web UI"
# One fetch, then match against the captured body with a here-string. Piping
# curl into `grep -q` looks tidier but is a trap: grep exits on first match,
# curl takes SIGPIPE, and `pipefail` then reports failure despite the match.
body="$(timeout -k 5 30 curl -sS -w '\n%{http_code}' "http://${HOST}:${PORT}/" 2>/dev/null)"
code="${body##*$'\n'}"
body="${body%$'\n'*}"

if [ "${code}" = "200" ]; then
    pass "HTTP 200 from http://${HOST}:${PORT}/"
else
    fail "web UI returned '${code}'"
fi

if grep -qi '<title>[[:space:]]*planefence[[:space:]]*</title>' <<<"${body}"; then
    pass "served the Planefence page"
else
    fail "response did not look like the Planefence UI"
    info "first title-ish line: $(grep -m1 -oiE '<title>[^<]*</title>' <<<"${body}")"
fi

step "Errors in the log"
bad="$(dock 60 logs "${CONTAINER}" 2>&1 | grep -icE 'did not signal ready|s6-overlay-suexec: fatal' || true)"
if [ "${bad}" = "0" ]; then
    pass "no fatal errors logged"
else
    fail "${bad} fatal error line(s) in the log"
    dock 60 logs "${CONTAINER}" 2>&1 | grep -iE 'did not signal ready|fatal' | head -5
fi

# ── Summary ─────────────────────────────────────────────────────────────
step "Summary"
printf '%d passed, %d failed\n' "${passed}" "${failed}"
[ "${failed}" -eq 0 ]
