#!/usr/bin/env bash
#
# Runs ON THE MAC. Copies the current working tree into the VM.
#
# This is a one-way copy rather than a Mac filesystem mount on purpose: the VM
# should be able to see this repository and nothing else on your machine.
# Tracked and untracked files are included; anything .gitignore'd is skipped.
set -euo pipefail

ORBSTACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Read by sync_repo() in common.sh.
# shellcheck disable=SC2034
REPO_ROOT="$(cd "${ORBSTACK_DIR}/.." && pwd)"
# shellcheck source=./common.sh
source "${ORBSTACK_DIR}/common.sh"

# `orb` only exists on the Mac. From the Claude sandbox we reach the same VM
# through DOCKER_HOST instead, so only check the machine exists when we can.
if command -v orb >/dev/null 2>&1; then
    vm_exists || die "machine '${ORB_VM}' does not exist — run ./.orbstack/provision.sh first"
fi

sync_repo
