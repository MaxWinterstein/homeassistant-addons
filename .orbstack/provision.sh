#!/usr/bin/env bash
#
# Runs ON THE MAC. Creates and provisions the throwaway Home Assistant
# add-on test VM in OrbStack. Safe to re-run — every step is idempotent.
#
#   ./.orbstack/provision.sh
#
# See .orbstack/README.md for the security model before running this.
set -euo pipefail

ORBSTACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Read by sync_repo() in common.sh.
# shellcheck disable=SC2034
REPO_ROOT="$(cd "${ORBSTACK_DIR}/.." && pwd)"
# shellcheck source=./common.sh
source "${ORBSTACK_DIR}/common.sh"

need orb "Install OrbStack first: https://orbstack.dev"

log "machine: ${ORB_VM}  distro: ${ORB_DISTRO}  docker port: ${DOCKER_TCP_PORT}"

if vm_exists; then
    log "machine '${ORB_VM}' already exists — reprovisioning"
else
    log "creating machine '${ORB_VM}'"
    orb create "${ORB_DISTRO}" "${ORB_VM}"
fi

# Keep VM ports off the local network, so only the Mac (and containers on it,
# such as the Claude sandbox) can reach the Docker daemon we are about to open.
# NOTE: this is a global OrbStack setting, not per-machine.
log "disabling 'expose ports to LAN' (global OrbStack setting)"
orb config set machines.expose_ports_to_lan false ||
    warn "could not set machines.expose_ports_to_lan — turn 'Expose ports to LAN' off manually in OrbStack settings"

run_vm_script vm/10-harden.sh
run_vm_script vm/20-docker.sh
run_vm_script vm/30-docker-tcp.sh
run_vm_script vm/40-ha-supervisor.sh

sync_repo

cat <<EOF

$(log "provisioning complete")

  Docker daemon   tcp://${VM_HOST}:${DOCKER_TCP_PORT}
  Workspace       ${ORB_VM}:${VM_WORKSPACE}

Next steps:

  # from the Mac — start a real HA + Supervisor instance in the VM
  task vm:ha:up
  open http://${VM_HOST}:8123

  # from the Claude sandbox — install a docker CLI and point it at the VM
  ./.orbstack/sandbox-setup.sh
  export DOCKER_HOST=tcp://${VM_HOST}:${DOCKER_TCP_PORT}

  # verify every hop
  ./.orbstack/doctor.sh

Throw the whole thing away at any time with:  task vm:destroy
EOF
