# shellcheck shell=bash
# Sourced by supervisor-up.sh and addon-test.sh — not meant to be run directly.

# WORKAROUND 3 (see supervisor-up.sh): make the workspace visible at the path
# the dev Supervisor bind-mounts into its build containers. Runs inside the
# ha-supervisor container. Idempotent, and repairs a bind that a later mount on
# /mnt/supervisor has hidden: it compares device and inode of what is actually
# visible instead of trusting `mountpoint`.
# shellcheck disable=SC2016,SC2034 # expanded inside the container; used by the sourcing scripts
BIND_APPS_LOCAL='
  src=/workspaces/addons dst=/mnt/supervisor/apps/local/addons
  mkdir -p "$dst"
  [ "$(stat -c %d:%i "$src")" = "$(stat -c %d:%i "$dst")" ] || mount --bind "$src" "$dst"
  [ "$(stat -c %d:%i "$src")" = "$(stat -c %d:%i "$dst")" ]
'
