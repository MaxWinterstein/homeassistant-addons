#!/usr/bin/env bash
#
# Runs INSIDE the Claude sandbox (or any container that has no Docker).
#
# The sandbox deliberately ships without Docker, so this installs just the
# static Docker *client* — no daemon, no privileges, no setuid — and points it
# at the Docker daemon in the OrbStack test VM.
#
# The sandbox filesystem is not persistent across container recreation, so
# re-run this whenever `docker` goes missing. It is cheap and idempotent.
set -euo pipefail

DOCKER_CLI_VERSION="${DOCKER_CLI_VERSION:-29.8.0}"
BUILDX_VERSION="${BUILDX_VERSION:-v0.37.0}"
PREFIX="${PREFIX:-${HOME}/.local/bin}"
ORB_VM="${ORB_VM:-ha-dev}"
DOCKER_TCP_PORT="${DOCKER_TCP_PORT:-2375}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*" >&2; }
die() {
    printf '\033[1;31mxxx\033[0m %s\n' "$*" >&2
    exit 1
}

case "$(uname -m)" in
aarch64 | arm64)
    CLI_ARCH="aarch64"
    BUILDX_ARCH="arm64"
    ;;
x86_64 | amd64)
    CLI_ARCH="x86_64"
    BUILDX_ARCH="amd64"
    ;;
*) die "unsupported architecture: $(uname -m)" ;;
esac

mkdir -p "${PREFIX}"

# ── Docker CLI ──────────────────────────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
    log "docker client already present: $(docker --version)"
else
    url="https://download.docker.com/linux/static/stable/${CLI_ARCH}/docker-${DOCKER_CLI_VERSION}.tgz"
    log "downloading docker client ${DOCKER_CLI_VERSION} (${CLI_ARCH})"
    tmp="$(mktemp -d)"
    trap 'rm -rf "${tmp}"' EXIT
    curl -fsSL "${url}" -o "${tmp}/docker.tgz" ||
        die "download failed: ${url}"
    tar -xzf "${tmp}/docker.tgz" -C "${tmp}" docker/docker
    install -m 0755 "${tmp}/docker/docker" "${PREFIX}/docker"
    log "installed ${PREFIX}/docker"
fi

# ── buildx plugin (optional) ────────────────────────────────────────────
# buildx is a client-side plugin, so it has to live here even though the
# builder itself runs in the VM. Only needed for multi-arch `docker buildx`
# builds; plain `docker build` works without it.
if [ -x "${HOME}/.docker/cli-plugins/docker-buildx" ]; then
    log "buildx plugin already present"
else
    log "downloading buildx ${BUILDX_VERSION} (${BUILDX_ARCH})"
    mkdir -p "${HOME}/.docker/cli-plugins"
    if curl -fsSL \
        "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${BUILDX_ARCH}" \
        -o "${HOME}/.docker/cli-plugins/docker-buildx"; then
        chmod 0755 "${HOME}/.docker/cli-plugins/docker-buildx"
        log "installed buildx plugin"
    else
        warn "buildx download failed — plain 'docker build' will still work"
        rm -f "${HOME}/.docker/cli-plugins/docker-buildx"
    fi
fi

# ── Point at the VM ─────────────────────────────────────────────────────
DOCKER_HOST_VALUE="tcp://${ORB_VM}.orb.local:${DOCKER_TCP_PORT}"

cat <<EOF

$(log "sandbox ready")

Add this to your shell (or let the taskfile targets set it for you):

  export DOCKER_HOST=${DOCKER_HOST_VALUE}

Then verify the whole chain:

  ./.orbstack/doctor.sh
EOF

case ":${PATH}:" in
*":${PREFIX}:"*) ;;
*) warn "${PREFIX} is not on PATH — add it: export PATH=\"${PREFIX}:\$PATH\"" ;;
esac
