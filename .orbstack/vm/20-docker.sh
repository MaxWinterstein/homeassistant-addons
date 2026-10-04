#!/usr/bin/env bash
#
# Runs INSIDE the VM as root.
# Installs Docker Engine from Docker's official apt repository, plus the
# buildx/compose plugins and QEMU binfmt handlers so the arm64 / amd64 /
# arm-v7 builds in taskfile.yml all work from a single machine.
set -euo pipefail

say() { echo "[docker] $*"; }

export DEBIAN_FRONTEND=noninteractive

if command -v docker >/dev/null 2>&1; then
    say "docker already installed ($(docker --version)) — skipping install"
else
    say "installing prerequisites"
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg git jq

    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID}" in
    ubuntu | debian) ;;
    *) echo "[docker] unsupported distro '${ID}' — expected ubuntu or debian" >&2 && exit 1 ;;
    esac

    say "adding Docker apt repository for ${ID} ${VERSION_CODENAME}"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
        -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
        >/etc/apt/sources.list.d/docker.list

    say "installing Docker Engine"
    apt-get update -qq
    apt-get install -y -qq \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
fi

systemctl enable --now docker
say "docker service: $(systemctl is-active docker)"

# Multi-arch emulation, so `--platform linux/arm/v7` and friends work here.
if [ ! -f /proc/sys/fs/binfmt_misc/qemu-arm ]; then
    say "installing QEMU binfmt handlers for cross-arch builds"
    docker run --privileged --rm tonistiigi/binfmt --install all
else
    say "binfmt handlers already present"
fi

# Pre-pull the tiny image doctor.sh uses for its isolation probe, so that
# check never has to wait on a registry round trip.
say "pre-pulling alpine:3 for doctor.sh probes"
docker pull --quiet alpine:3 >/dev/null || say "WARNING: could not pre-pull alpine:3"

say "done"
