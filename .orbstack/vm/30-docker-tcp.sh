#!/usr/bin/env bash
#
# Runs INSIDE the VM as root.
#
# Opens the Docker daemon on a TCP port so the Claude sandbox (a separate
# container on the Mac, with no Docker of its own) can drive builds and
# container tests in here via DOCKER_HOST.
#
# ⚠️  This endpoint is UNAUTHENTICATED and UNENCRYPTED. Anyone who can reach
#     it has root-equivalent control of this VM. That is an accepted trade-off
#     *only* because this VM is disposable and holds nothing of value:
#       - Mac file sharing is removed (10-harden.sh)
#       - no credentials, tokens or SSH keys live here
#       - ports are kept off the LAN (machines.expose_ports_to_lan=false)
#     Keep it that way, or switch to a TLS/SSH-authenticated setup.
#
# If you ever move development entirely into this VM, delete this step — a
# local unix socket needs no open port.
set -euo pipefail

say() { echo "[docker-tcp] $*"; }

PORT="${DOCKER_TCP_PORT:-2375}"

mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/10-tcp-listener.conf <<UNIT
# Managed by .orbstack/vm/30-docker-tcp.sh — do not edit by hand.
# Adds a TCP listener alongside the socket-activated unix socket.
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:${PORT} --containerd=/run/containerd/containerd.sock
UNIT

say "restarting docker with a TCP listener on :${PORT}"
systemctl daemon-reload
systemctl restart docker

# Wait for the daemon to answer before declaring success.
for _ in $(seq 1 20); do
    if curl -fsS --max-time 2 "http://127.0.0.1:${PORT}/_ping" >/dev/null 2>&1; then
        say "daemon is answering on :${PORT}"
        say "done"
        exit 0
    fi
    sleep 1
done

echo "[docker-tcp] ERROR: daemon did not answer on :${PORT} after 20s" >&2
systemctl status docker --no-pager --lines 20 >&2 || true
exit 1
