#!/usr/bin/env bash
#
# Verifies the whole chain, hop by hop. Run it from the Claude sandbox (the
# interesting case) or from the Mac.
#
#   ./.orbstack/doctor.sh          # fast checks
#   ./.orbstack/doctor.sh --deep   # also does a real cross-arch container run
#
# Exit code is non-zero if any check FAILs. WARNs do not fail the run.
set -uo pipefail

ORB_VM="${ORB_VM:-ha-dev}"
DOCKER_TCP_PORT="${DOCKER_TCP_PORT:-2375}"
VM_HOST="${ORB_VM}.orb.local"
DEEP=0
[ "${1:-}" = "--deep" ] && DEEP=1

fails=0
warns=0

pass() { printf '\033[1;32m PASS \033[0m %s\n' "$*"; }
fail() {
    printf '\033[1;31m FAIL \033[0m %s\n' "$*"
    fails=$((fails + 1))
}
warn() {
    printf '\033[1;33m WARN \033[0m %s\n' "$*"
    warns=$((warns + 1))
}
info() { printf '\033[2m      %s\033[0m\n' "$*"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# The docker CLI has no client-side timeout and will happily hang for minutes
# against an unreachable daemon, so wrap every daemon-touching call.
#
# -k is essential: `docker run` forwards SIGTERM to the *container* rather than
# exiting itself, so a plain `timeout` cannot kill a CLI that is still pulling
# an image. The follow-up SIGKILL can not be forwarded or ignored.
#
# `timeout` is coreutils: present on Linux, absent on stock macOS.
DOCKER_TIMEOUT="${DOCKER_TIMEOUT:-25}"
if command -v timeout >/dev/null 2>&1; then
    dock() { timeout -k 5 "${DOCKER_TIMEOUT}" docker "$@"; }
elif command -v gtimeout >/dev/null 2>&1; then
    dock() { gtimeout -k 5 "${DOCKER_TIMEOUT}" docker "$@"; }
else
    dock() { docker "$@"; }
fi

# ── 0. proxy preflight ──────────────────────────────────────────────────
# VibePod runs an inspecting HTTP proxy. Ordinary Docker API calls survive it,
# but `docker run` needs HTTP connection hijacking for attach, which the proxy
# breaks — and the CLI then *hangs* rather than failing, which is a miserable
# thing to debug. Exempt the local VM so container commands work.
if [ -n "${HTTP_PROXY:-}${http_proxy:-}" ]; then
    case ",${NO_PROXY:-},${no_proxy:-}," in
    *.orb.local*) ;;
    *)
        head_ "0. Proxy configuration"
        warn "proxy is set but .orb.local is not in NO_PROXY — 'docker run' would hang"
        info "exporting it for this run; make it permanent in .vibepod/config.yaml"
        export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1},.orb.local"
        export no_proxy="${NO_PROXY}"
        ;;
    esac
fi

# ── 1. name resolution ──────────────────────────────────────────────────
head_ "1. Can we resolve the VM?"
if getent hosts "${VM_HOST}" >/dev/null 2>&1; then
    pass "${VM_HOST} resolves"
    info "$(getent hosts "${VM_HOST}" | head -1)"
elif getent hosts orb.local >/dev/null 2>&1; then
    fail "${VM_HOST} does not resolve, but orb.local does — is the machine created and running?"
    info "try: orb list    /    ./.orbstack/provision.sh"
else
    fail "OrbStack DNS is not reachable from here (orb.local does not resolve)"
    info "this environment may not be on OrbStack's network at all"
fi

# ── 2. daemon reachable ─────────────────────────────────────────────────
# Everything after this depends on the daemon, so remember the result and skip
# the doomed round trips rather than letting each one burn its timeout.
daemon_ok=0
head_ "2. Is the Docker daemon reachable?"
if curl -fsS --max-time 5 "http://${VM_HOST}:${DOCKER_TCP_PORT}/_ping" >/dev/null 2>&1; then
    pass "daemon answers on tcp://${VM_HOST}:${DOCKER_TCP_PORT}"
    daemon_ok=1
else
    fail "no answer on tcp://${VM_HOST}:${DOCKER_TCP_PORT}"
    info "in the VM: systemctl status docker"
fi

# ── 3. docker client ────────────────────────────────────────────────────
head_ "3. Do we have a Docker client wired up?"
if command -v docker >/dev/null 2>&1; then
    pass "docker client present: $(docker --version 2>/dev/null)"
    if [ -z "${DOCKER_HOST:-}" ]; then
        warn "DOCKER_HOST is not set — exporting for this run only"
        export DOCKER_HOST="tcp://${VM_HOST}:${DOCKER_TCP_PORT}"
    fi
    info "DOCKER_HOST=${DOCKER_HOST}"
    if [ "${daemon_ok}" = "0" ]; then
        fail "cannot verify the client/daemon handshake — daemon unreachable (see check 2)"
    elif server="$(dock version --format '{{.Server.Version}}' 2>/dev/null)" && [ -n "${server}" ]; then
        pass "talking to daemon, server version ${server}"
    else
        fail "daemon answers on TCP but the client handshake failed"
        # Strip HTML (a proxy error page), then prefer the actual error line
        # over the leading "Client:" banner.
        detail="$(dock version 2>&1 | sed -e 's/<[^>]*>//g' -e 's/^[[:space:]]*//' |
            grep -m1 -iE 'error|cannot|refused|denied|timeout|failure|no such host' |
            cut -c1-120)"
        info "${detail:-see: docker version}"
    fi
else
    fail "no docker client — run ./.orbstack/sandbox-setup.sh"
fi

# ── 4. Mac filesystem must NOT be visible in the VM ─────────────────────
head_ "4. Is the Mac filesystem really unmounted in the VM?"
# This check is security-critical, so "could not run the probe" must never be
# reported as "verified". Only a probe container that actually ran and came
# back empty counts as a pass.
if [ "${daemon_ok}" = "0" ]; then
    fail "could NOT verify isolation — daemon unreachable (see check 2)"
    info "this is not a pass: bring the VM up, then re-run"
elif command -v docker >/dev/null 2>&1 && [ -n "${DOCKER_HOST:-}" ]; then
    if probe="$(dock run --rm -v /:/host:ro alpine:3 \
        sh -c 'ls -A /host/mnt/mac 2>/dev/null | head -5' 2>/dev/null)"; then
        if [ -z "${probe}" ]; then
            pass "/mnt/mac is empty inside the VM"
        else
            fail "Mac files ARE visible in the VM — hardening did not stick"
            info "saw: $(echo "${probe}" | tr '\n' ' ')"
            info "re-run: orb -m ${ORB_VM} -u root /usr/local/sbin/no-mac-mount"
        fi
    else
        fail "could NOT verify isolation — the probe container did not run"
        info "this is not a pass: fix checks 1-3 first, then re-run"
    fi
else
    fail "could NOT verify isolation — no working docker client"
    info "this is not a pass: run ./.orbstack/sandbox-setup.sh first"
fi

# ── 5. multi-arch support ───────────────────────────────────────────────
head_ "5. Can the VM build for all the add-on architectures?"
if [ "${daemon_ok}" = "0" ]; then
    warn "skipped — daemon unreachable (see check 2)"
elif command -v docker >/dev/null 2>&1 && [ -n "${DOCKER_HOST:-}" ]; then
    if [ "${DEEP}" = "1" ]; then
        for platform in linux/amd64 linux/arm64 linux/arm/v7; do
            if out="$(dock run --rm --platform "${platform}" alpine:3 uname -m 2>/dev/null)"; then
                pass "${platform} runs (uname -m: ${out})"
            else
                fail "${platform} cannot run — binfmt handlers missing?"
            fi
        done
    else
        info "skipped the real cross-arch run (pass --deep to include it)"
        if docker buildx version >/dev/null 2>&1; then
            pass "buildx plugin available: $(docker buildx version 2>/dev/null | head -1)"
        else
            warn "no buildx plugin locally — plain 'docker build' still works"
        fi
    fi
else
    warn "skipped — needs a working docker client"
fi

# ── 6. HA supervisor test instance ──────────────────────────────────────
head_ "6. Is the Home Assistant test instance up?"
if curl -fsS --max-time 5 -o /dev/null "http://${VM_HOST}:8123" 2>/dev/null; then
    pass "Home Assistant answers at http://${VM_HOST}:8123"
else
    warn "not running (that is fine unless you want it): task vm:ha:up"
fi

# ── summary ─────────────────────────────────────────────────────────────
head_ "Summary"
if [ "${fails}" -eq 0 ]; then
    printf 'all good — %d warning(s)\n' "${warns}"
    exit 0
fi
printf '%d check(s) failed, %d warning(s)\n' "${fails}" "${warns}"
exit 1
