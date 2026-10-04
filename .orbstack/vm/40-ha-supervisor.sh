#!/usr/bin/env bash
#
# Runs INSIDE the VM as root.
#
# Sets up the real Home Assistant + Supervisor test bench using the official
# add-on devcontainer image, which is what the Home Assistant add-on docs mean
# by "use the devcontainer". It runs docker-in-docker and needs --privileged,
# which is exactly why it belongs in a disposable VM rather than on the Mac.
#
# The add-ons in ${VM_WORKSPACE} show up inside HA as a local add-on
# repository, so you can install and start them like a user would.
set -euo pipefail

say() { echo "[ha] $*"; }

WORKSPACE="${VM_WORKSPACE:-/opt/addons}"
IMAGE="ghcr.io/home-assistant/devcontainer:addons"

mkdir -p "${WORKSPACE}"

say "pulling ${IMAGE} (this is a big image, first run takes a while)"
docker pull "${IMAGE}"

# Persistent docker-in-docker storage, so HA Core and add-on images survive a
# restart of the supervisor container.
docker volume create ha-supervisor-dind >/dev/null

install -m 0755 /dev/stdin /usr/local/bin/ha-supervisor-up <<HELPER
#!/usr/bin/env bash
#
# Start the Home Assistant Supervisor test instance.
#   ha-supervisor-up            # foreground, Ctrl-C to stop
#   HA_DETACH=1 ha-supervisor-up  # background
#
# HA UI:       http://\$(hostname).orb.local:8123
# Observer:    http://\$(hostname).orb.local:4357
set -euo pipefail

WORKSPACE="\${WORKSPACE:-${WORKSPACE}}"
IMAGE="${IMAGE}"

docker rm -f ha-supervisor >/dev/null 2>&1 || true

run_flags=(--rm --name ha-supervisor --privileged)
if [ "\${HA_DETACH:-0}" = "1" ]; then
  # -t even when detached: supervisor_run calls stty and exits 1 without a TTY.
  run_flags+=(-d -t)
else
  run_flags+=(-it)
fi

exec docker run "\${run_flags[@]}" \\
  -v ha-supervisor-dind:/var/lib/docker \\
  -v "\${WORKSPACE}:/workspaces/addons" \\
  -e WORKSPACE_DIRECTORY=/workspaces/addons \\
  -p 8123:8123 \\
  -p 4357:4357 \\
  "\${IMAGE}" \\
  bash -lc 'bash /usr/bin/devcontainer_bootstrap && supervisor_run'
HELPER

install -m 0755 /dev/stdin /usr/local/bin/ha-supervisor-down <<'HELPER'
#!/usr/bin/env bash
# Stop the Home Assistant Supervisor test instance.
set -euo pipefail
docker rm -f ha-supervisor 2>/dev/null && echo "stopped" || echo "not running"
HELPER

say "installed ha-supervisor-up / ha-supervisor-down"
say "done"
