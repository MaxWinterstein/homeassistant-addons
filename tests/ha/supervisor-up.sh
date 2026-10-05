#!/usr/bin/env bash
#
# Bring up a real Home Assistant + Supervisor in the OrbStack VM, ready to
# install add-ons from this repository.
#
# Idempotent: if it is already running with Core up, this returns immediately.
#
#   tests/ha/supervisor-up.sh
#   tests/ha/supervisor-up.sh --recreate    # tear down and start clean
#
# ─── About the workarounds below ────────────────────────────────────────
# The official add-on devcontainer image and the dev Supervisor it pulls have
# drifted apart, so three things have to be patched up by hand. Each is
# marked WORKAROUND with what breaks without it. Re-check them when the
# devcontainer image is updated — they should eventually all disappear.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

CONTAINER="${HA_CONTAINER:-ha-supervisor}"
IMAGE="ghcr.io/home-assistant/devcontainer:addons"
WORKSPACE="${VM_WORKSPACE:-/opt/addons}"
CORE_TIMEOUT="${CORE_TIMEOUT:-900}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*" >&2; }
die() {
    printf '\033[1;31mxxx\033[0m %s\n' "$*" >&2
    exit 1
}

dock() { timeout -k 5 "${1}" docker "${@:2}"; }

# shellcheck source=./common.sh
source tests/ha/common.sh
in_vm() { dock "${1}" exec "${CONTAINER}" "${@:2}"; }
ha_cli() { dock "${1}" exec "${CONTAINER}" docker exec hassio_cli ha "${@:2}"; }

command -v docker >/dev/null 2>&1 || die "no docker client (run .orbstack/sandbox-setup.sh)"
dock 30 version >/dev/null 2>&1 || die "no Docker daemon — see .orbstack/doctor.sh"

[ "${1:-}" = "--recreate" ] && {
    log "removing existing ${CONTAINER}"
    dock 90 rm -f "${CONTAINER}" >/dev/null 2>&1
}

# ── Start the devcontainer ──────────────────────────────────────────────
if [ "$(dock 30 inspect -f '{{.State.Running}}' "${CONTAINER}" 2>/dev/null)" = "true" ]; then
    log "${CONTAINER} already running"
else
    dock 90 rm -f "${CONTAINER}" >/dev/null 2>&1
    log "starting ${CONTAINER} (first run pulls ~2GB, then HA Core on top)"

    # WORKAROUND 1: -t is required even though we detach. supervisor_run calls
    # stty, which fails without a TTY and takes the container down with exit 1.
    #
    # devcontainer_bootstrap is mode 0644 in the image, so it must be invoked
    # via `bash`, exactly as the official devcontainer.json does.
    #
    # WORKAROUND 5: give the Supervisor the /run/os mount it expects
    # (PATCH_SUPERVISOR_RUN in common.sh), before supervisor_run starts it.
    START_CMD="set -e
${PATCH_SUPERVISOR_RUN}
set +e
bash /usr/bin/devcontainer_bootstrap && supervisor_run"
    dock 120 run -d -t --name "${CONTAINER}" --privileged \
        -v ha-supervisor-dind:/var/lib/docker \
        -v "${WORKSPACE}:/workspaces/addons" \
        -e WORKSPACE_DIRECTORY=/workspaces/addons \
        -p 8123:8123 -p 4357:4357 \
        "${IMAGE}" \
        bash -lc "${START_CMD}" >/dev/null ||
        die "could not start ${CONTAINER}"
fi

# ── Wait for the Supervisor to be answering ─────────────────────────────
log "waiting for the Supervisor"
for _ in $(seq 1 60); do
    ha_cli 30 info >/dev/null 2>&1 && break
    sleep 5
done
ha_cli 30 info >/dev/null 2>&1 || {
    dock 60 logs "${CONTAINER}" 2>&1 | tail -20
    die "Supervisor never came up"
}
log "Supervisor is answering"

# ── Patch up the devcontainer/Supervisor drift ──────────────────────────
# WORKAROUND 2: HA Core binds /run/supervisor, which nothing in the
# devcontainer creates. Without it Core never starts:
#   "invalid mount config ... bind source path does not exist: /run/supervisor"
# and /mnt/supervisor must be a shared mount or Core refuses to start:
#   "path /mnt/supervisor/media is mounted on / but it is not a shared mount"
log "applying mount workarounds"
in_vm 90 sh -c '
  mkdir -p /run/supervisor
  mountpoint -q /mnt/supervisor || mount --bind /mnt/supervisor /mnt/supervisor
  mount --make-rshared /mnt/supervisor
' >/dev/null 2>&1 || warn "mount workarounds reported an error"

# WORKAROUND 3: the dev Supervisor renamed its data layout addons -> apps, but
# devcontainer_bootstrap still bind-mounts the workspace at the old path, so
# builds fail with:
#   "bind source path does not exist: /mnt/supervisor/apps/local/addons/<addon>"
# Compares what is visible rather than asking `mountpoint`: running this script
# again stacks a fresh mount on /mnt/supervisor, which hides an earlier bind
# that `mountpoint` still reports, and the Supervisor then sees an empty folder.
in_vm 90 sh -c "${BIND_APPS_LOCAL}" >/dev/null 2>&1 ||
    warn "could not bind the apps/local workspace path"

# WORKAROUND 4: the Supervisor marks the system unhealthy with
# docker_gateway_unprotected, because applying its firewall rules needs a real
# systemd over D-Bus and PID 1 here is a shell script. That blocks every
# install. Tell the job system to ignore the health condition — a supported
# escape hatch, and safe in a throwaway test VM.
log "ignoring the 'healthy' job condition (docker_gateway_unprotected)"
ha_cli 60 jobs options --ignore-conditions healthy >/dev/null 2>&1 ||
    warn "could not set ignore-conditions"

# WORKAROUND 5, part 2: the devcontainer runs the Supervisor with
# SUPERVISOR_DEV=1, which puts it on the dev channel and makes it install a dev
# Core, even with a stable Supervisor (part 1 in common.sh). Switch the channel
# to what real installs run; Core is brought in line further down.
log "switching the Supervisor to the ${HA_CHANNEL:-stable} channel"
if ! {
    ha_cli 60 supervisor options --channel "${HA_CHANNEL:-stable}" >/dev/null 2>&1 &&
        ha_cli 60 supervisor reload >/dev/null 2>&1
}; then
    warn "could not switch the Supervisor channel"
fi

# ── Make sure Core is running ───────────────────────────────────────────
state="$(ha_cli 60 core info 2>/dev/null | awk '/^state:/{print $2}')"
if [ "${state}" != "running" ]; then
    log "starting Home Assistant Core (this pulls ~600MB the first time)"
    ha_cli "${CORE_TIMEOUT}" core start >/dev/null 2>&1
fi

log "waiting for Core"
for _ in $(seq 1 60); do
    if dock 30 exec "${CONTAINER}" docker ps --filter name=homeassistant --format '{{.Names}}' 2>/dev/null | grep -q homeassistant; then
        break
    fi
    sleep 10
done

core_status="$(dock 30 exec "${CONTAINER}" docker ps --filter name=homeassistant --format '{{.Status}}' 2>/dev/null | head -1)"
if [ -n "${core_status}" ]; then
    log "Home Assistant Core: ${core_status}"
else
    warn "Core is not running yet; add-on installs may still work"
    dock 60 logs "${CONTAINER}" 2>&1 | grep -iE "can't start home assistant|error" | grep -v DEBUG | tail -5
fi

# Wait until no Core job (start/update/restart) is running; a new one is
# refused with "Another job is running for job group home_assistant_core".
wait_for_core_jobs() {
    for _ in $(seq 1 80); do
        running="$(ha_cli 30 jobs info --raw-json 2>/dev/null |
            jq '[.data.jobs[]? | select((.done | not) and (.name | startswith("home_assistant_core")))] | length' 2>/dev/null)"
        [ "${running:-1}" = "0" ] && return 0
        sleep 15
    done
    return 1
}

# ── Core on the channel's version ───────────────────────────────────────
# The target comes from the channel file itself: right after the channel
# switch, the Supervisor's own version_latest can still be the dev one.
core_version="$(ha_cli 60 core info --raw-json 2>/dev/null | jq -r '.data.version // empty')"
core_latest="$(in_vm 60 sh -c "curl -fsS https://version.home-assistant.io/${HA_CHANNEL:-stable}.json" 2>/dev/null |
    jq -r '.homeassistant.default // empty')"
if [ -n "${core_latest}" ] && [ "${core_version}" != "${core_latest}" ]; then
    log "Core is ${core_version}, installing ${core_latest} from the ${HA_CHANNEL:-stable} channel"
    wait_for_core_jobs || warn "Core jobs still running, trying anyway"
    # Reports a failure when the previous start attempt timed out, even though
    # the new version comes up fine; check the version instead of the exit code.
    ha_cli "${CORE_TIMEOUT}" core update --version "${core_latest}" >/dev/null 2>&1
    core_version="$(ha_cli 60 core info --raw-json 2>/dev/null | jq -r '.data.version // empty')"
    [ "${core_version}" = "${core_latest}" ] || warn "Core is ${core_version:-unknown}, expected ${core_latest}"
fi
log "Home Assistant Core ${core_version:-unknown}"

# ── A real location for HOMEASSISTANT_* placeholders ────────────────────
# Without onboarding Core reports latitude/longitude 0 and UTC, so placeholder
# resolution in add-ons can't be told apart from a failure. Seed a location
# once (HA migrates the file to its current format on start).
CORE_CONFIG=/mnt/supervisor/homeassistant/.storage/core.config
if ! in_vm 30 test -f "${CORE_CONFIG}"; then
    log "seeding a test location (${TEST_LATITUDE:-50.0379}, ${TEST_LONGITUDE:-8.5622}, ${TEST_TIMEZONE:-Europe/Berlin})"
    if ! {
        jq -n \
            --argjson lat "${TEST_LATITUDE:-50.0379}" \
            --argjson lon "${TEST_LONGITUDE:-8.5622}" \
            --argjson ele "${TEST_ELEVATION:-111}" \
            --arg tz "${TEST_TIMEZONE:-Europe/Berlin}" \
            '{version: 1, minor_version: 1, key: "core.config",
          data: {latitude: $lat, longitude: $lon, elevation: $ele,
                 unit_system: "metric", location_name: "Add-on test bench",
                 time_zone: $tz, external_url: null, internal_url: null,
                 currency: "EUR"}}' |
            dock 30 exec -i "${CONTAINER}" sh -c "cat > '${CORE_CONFIG}'" &&
            wait_for_core_jobs &&
            ha_cli "${CORE_TIMEOUT}" core restart >/dev/null 2>&1
    }; then
        warn "could not seed the test location"
    fi
fi

host="$(echo "${DOCKER_HOST:-localhost}" | sed -e 's|^tcp://||' -e 's|:.*||')"
cat <<EOF

$(log "ready")

  Home Assistant   http://${host}:8123
  Observer         http://${host}:4357

  Install an add-on:  tests/ha/addon-test.sh planefence
  Stop everything:    docker rm -f ${CONTAINER}
EOF
