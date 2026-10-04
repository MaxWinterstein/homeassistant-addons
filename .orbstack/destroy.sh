#!/usr/bin/env bash
#
# Runs ON THE MAC. Deletes the throwaway test VM and everything in it.
# This is the intended recovery path for "something went wrong in the VM" —
# nothing of value should ever live there.
set -euo pipefail

ORBSTACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${ORBSTACK_DIR}/common.sh"

need orb

if ! vm_exists; then
    log "machine '${ORB_VM}' does not exist — nothing to do"
    exit 0
fi

if [ "${FORCE:-0}" != "1" ]; then
    printf 'Delete OrbStack machine "%s" and all its data? [y/N] ' "${ORB_VM}"
    read -r reply
    case "${reply}" in
    y | Y | yes | YES) ;;
    *)
        log "aborted"
        exit 0
        ;;
    esac
fi

log "deleting machine '${ORB_VM}'"
orb delete "${ORB_VM}"
log "gone. re-create it with: ./.orbstack/provision.sh"
