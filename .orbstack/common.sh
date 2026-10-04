#!/usr/bin/env bash
# Shared configuration + helpers for the Mac-side OrbStack scripts.
# Sourced by provision.sh / destroy.sh / sync.sh — not meant to be run directly.

# ── Configuration (override via environment) ────────────────────────────
ORB_VM="${ORB_VM:-ha-dev}"
ORB_DISTRO="${ORB_DISTRO:-ubuntu}"
DOCKER_TCP_PORT="${DOCKER_TCP_PORT:-2375}"
VM_WORKSPACE="${VM_WORKSPACE:-/opt/addons}"
# Used by the scripts that source this file, not here.
# shellcheck disable=SC2034
VM_HOST="${ORB_VM}.orb.local"

# ── Output helpers ──────────────────────────────────────────────────────
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*" >&2; }
die() {
    printf '\033[1;31mxxx\033[0m %s\n' "$*" >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null 2>&1 ||
        die "'$1' not found in PATH. ${2:-}"
}

# ── OrbStack helpers ────────────────────────────────────────────────────

# True if the machine already exists.
vm_exists() {
    orb list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "${ORB_VM}"
}

# Run a command inside the VM as root.
vm_root() {
    orb -m "${ORB_VM}" -u root "$@"
}

# Copy a provisioning script into the VM and execute it as root.
# The script is passed base64-encoded as an argument rather than over stdin,
# so it works regardless of how `orb` handles an interactive stdin.
run_vm_script() {
    local rel="$1"
    local src="${ORBSTACK_DIR}/${rel}"
    local base payload
    [ -f "${src}" ] || die "missing provisioning script: ${src}"
    base="$(basename "${rel}")"
    payload="$(base64 <"${src}" | tr -d '\n')"

    log "running ${rel} inside ${ORB_VM}"
    vm_root bash -c "
    set -euo pipefail
    export DOCKER_TCP_PORT='${DOCKER_TCP_PORT}'
    export VM_WORKSPACE='${VM_WORKSPACE}'
    printf %s '${payload}' | base64 -d > '/tmp/${base}'
    bash '/tmp/${base}'
    rm -f '/tmp/${base}'
  "
}

# Push the current working tree (tracked + untracked, honouring .gitignore)
# into the VM. Used instead of a Mac filesystem mount, so the VM only ever
# sees a copy of this one repository.
#
# Two transports, because this is also useful from the Claude sandbox, which
# has a docker client but no `orb`:
#   - orb    : the normal path, run from the Mac
#   - docker : pipe a tar through a throwaway container that mounts the target
sync_repo() {
    local list count
    need git

    list="$(mktemp)"
    (cd "${REPO_ROOT}" && git ls-files -co --exclude-standard >"${list}")
    count="$(wc -l <"${list}" | tr -d ' ')"

    if command -v orb >/dev/null 2>&1; then
        log "syncing ${count} files -> ${ORB_VM}:${VM_WORKSPACE} (via orb)"
        vm_root bash -c "mkdir -p '${VM_WORKSPACE}'"
        tar -C "${REPO_ROOT}" -cf - -T "${list}" |
            vm_root bash -c "tar xf - -C '${VM_WORKSPACE}'"
    elif command -v docker >/dev/null 2>&1 &&
        docker version >/dev/null 2>&1; then
        log "syncing ${count} files -> ${VM_WORKSPACE} (via docker, no orb here)"
        # Clear first, so files deleted since the last sync do not linger.
        tar -C "${REPO_ROOT}" -cf - -T "${list}" |
            docker run -i --rm -v "${VM_WORKSPACE}:/dest" alpine:3 \
                sh -c 'rm -rf /dest/* /dest/.[!.]* 2>/dev/null; tar x -C /dest'
    else
        rm -f "${list}"
        die "need either 'orb' (on the Mac) or a reachable docker daemon to sync"
    fi

    rm -f "${list}"
    log "synced ${count} files"
}
