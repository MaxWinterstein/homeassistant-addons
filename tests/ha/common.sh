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

# WORKAROUND 5 (see supervisor-up.sh), two parts. The devcontainer always runs
# the dev channel (version.home-assistant.io/dev.json); there, Supervisor and
# Core are mid-migration and never complete their token handshake, so every
# add-on call to /core/api/... got a 502 and HOMEASSISTANT_* placeholders could
# never be resolved. Use the channel real installs run (HA_CHANNEL, default
# stable). Also, the dev Supervisor talks to Core over
# the unix socket /run/os/core.sock, which Core creates in /run/supervisor.
# HA OS mounts /run/supervisor at /run/os for the Supervisor; the devcontainer's
# supervisor_run doesn't, so every add-on call to /core/api/... got a 502 and
# HOMEASSISTANT_* placeholders could never be resolved. Adds the mount; runs
# inside the devcontainer before supervisor_run, idempotent.
# shellcheck disable=SC2016,SC2034 # expanded inside the container; used by the sourcing scripts
PATCH_SUPERVISOR_RUN="
  sed -i 's|version.home-assistant.io/dev.json|version.home-assistant.io/${HA_CHANNEL:-stable}.json|' /etc/supervisor_scripts/common
  grep -q 'version.home-assistant.io/${HA_CHANNEL:-stable}.json' /etc/supervisor_scripts/common
"'
  f=/usr/bin/supervisor_run
  grep -q "/run/supervisor:/run/os" "$f" ||
    sed -i "/-v \/run\/udev:\/run\/udev:ro/a\        -v /run/supervisor:/run/os:rw \\\\" "$f"
  grep -q "/run/supervisor:/run/os:rw" "$f"
'
