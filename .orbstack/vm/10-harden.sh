#!/usr/bin/env bash
#
# Runs INSIDE the VM as root.
#
# Removes OrbStack's Mac file sharing from this machine. OrbStack mounts the
# whole Mac filesystem at /mnt/mac by default (and exposes Mac paths like
# /Users directly), which would defeat the point of putting an unauthenticated
# Docker daemon in here.
#
# OrbStack does not document a supported switch to disable this mount, so this
# is best-effort defense in depth: unmount now, and unmount again on every
# boot. `.orbstack/doctor.sh` verifies it actually stuck — treat that check as
# the source of truth, not this script's exit code.
set -euo pipefail

say() { echo "[harden] $*"; }

unmount_mac() {
    local mp

    # Deepest mountpoints first, so nested mounts come off cleanly.
    while read -r mp; do
        [ -n "${mp}" ] || continue
        say "unmounting ${mp}"
        umount -l "${mp}" 2>/dev/null || true
    done < <(awk '$2 ~ /^\/mnt\/mac/ {print $2}' /proc/mounts | sort -r)

    # Mac paths are also surfaced at the root as symlinks into /mnt/mac.
    local link
    for link in /Users /Volumes /opt/homebrew; do
        if [ -L "${link}" ]; then
            say "removing symlink ${link}"
            rm -f "${link}"
        fi
    done
}

unmount_mac

if mountpoint -q /mnt/mac 2>/dev/null; then
    say "WARNING: /mnt/mac is still a mountpoint"
else
    say "/mnt/mac is not mounted"
fi

# Re-apply on every boot: OrbStack's guest agent re-establishes the mount, and
# it may appear slightly after multi-user.target, so retry for a short while.
mkdir -p /usr/local/sbin
install -m 0755 /dev/stdin /usr/local/sbin/no-mac-mount <<'HELPER'
#!/usr/bin/env bash
# Unmount OrbStack Mac file sharing. Retries briefly, because the mount can
# appear a moment after boot.
set -uo pipefail
for _ in $(seq 1 30); do
  while read -r mp; do
    [ -n "${mp}" ] || continue
    umount -l "${mp}" 2>/dev/null || true
  done < <(awk '$2 ~ /^\/mnt\/mac/ {print $2}' /proc/mounts | sort -r)
  for link in /Users /Volumes /opt/homebrew; do
    [ -L "${link}" ] && rm -f "${link}"
  done
  sleep 1
done
exit 0
HELPER

cat >/etc/systemd/system/no-mac-mount.service <<'UNIT'
[Unit]
Description=Unmount OrbStack Mac file sharing (defense in depth)
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/no-mac-mount
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable no-mac-mount.service >/dev/null 2>&1 || true
say "installed no-mac-mount.service (runs on every boot)"
say "done"
