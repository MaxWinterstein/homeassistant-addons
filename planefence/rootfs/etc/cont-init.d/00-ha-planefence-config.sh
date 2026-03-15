#!/usr/bin/with-contenv bashio
# Generate/update planefence.config from Home Assistant add-on options.
# Runs via legacy-cont-init before planefence services start.
#
# The symlink /usr/share/planefence/persist -> /config/planefence is created
# at build time in the Dockerfile, so all s6 services see it immediately.
# This script just ensures the target directory exists and writes the config.
#
# First start: copies /planefence.config.template (saved at build time)
#              so the user has a fully documented config to customise.
# Every start:  updates only the keys managed by HA add-on options; all other
#              lines (custom settings added by the user) are left untouched.

# Source HA options as environment variables
. /export-env-from-config.sh

# The Dockerfile created /usr/share/planefence/persist -> /var/lib/planefence-persist
# so s6 services can start cleanly. Now re-point to the real persistent location.
#
# Priority:
#   1. /addon_configs/planefence  – real HA with addon_config:rw mapping (also used by taskfile)
#   2. /config/planefence         – legacy HA config mount
#   3. /var/lib/planefence-persist – ephemeral stub (nothing else available)
if [ -d /addon_configs ]; then
    DATA_PERSIST="/addon_configs/planefence"
    echo "[ha-planefence-config] Using /addon_configs/planefence for persistent storage"
elif [ -d /config ]; then
    DATA_PERSIST="/config/planefence"
    echo "[ha-planefence-config] Using /config/planefence for persistent storage"
else
    DATA_PERSIST="/var/lib/planefence-persist"
    echo "[ha-planefence-config] WARNING: no persistent mount found, using ephemeral stub"
fi

mkdir -p "${DATA_PERSIST}"
mkdir -p "${DATA_PERSIST}/.internal"

# Re-point the symlink if it's not already pointing to the right place.
if [ "$(readlink /usr/share/planefence/persist)" != "${DATA_PERSIST}" ]; then
    # Copy anything the early s6 services may have written to the stub.
    cp -rn /var/lib/planefence-persist/. "${DATA_PERSIST}/" 2>/dev/null || true
    ln -sfn "${DATA_PERSIST}" /usr/share/planefence/persist
    echo "[ha-planefence-config] Re-pointed /usr/share/planefence/persist -> ${DATA_PERSIST}"
fi

CONFIG_FILE="${DATA_PERSIST}/planefence.config"
SAVED_TEMPLATE="${DATA_PERSIST}/planefence.config.RENAME-and-EDIT-me"

# Copy the upstream template to the persistent dir on first start so the
# user can edit it. The template was saved to /planefence.config.template
# in the Dockerfile before the persist dir was replaced with a symlink.
if [ ! -f "${SAVED_TEMPLATE}" ] && [ -f /planefence.config.template ]; then
    cp /planefence.config.template "${SAVED_TEMPLATE}"
    echo "[ha-planefence-config] Copied upstream template to ${SAVED_TEMPLATE}"
fi

# get-pa-alertlist.sh requires these files to exist or it crashes.
touch "${DATA_PERSIST}/plane-alert-db.txt"
touch "${DATA_PERSIST}/.internal/plane-alert-db.txt"

# Helper: set KEY=VALUE in config file.
# Updates the existing line in-place, or appends if the key is absent.
# Writes raw (unquoted) values — planefence.config is parsed by upstream
# scripts using grep/cut as well as bash source, so shell-quoting would
# embed literal quote characters in values read by those tools.
# Special characters in sed replacement strings (&, \, /, |) are escaped.
set_config() {
    local key="$1"
    local value="$2"
    local escaped_value
    escaped_value=$(printf '%s\n' "${value}" | sed 's/[&\\/|]/\\&/g')
    if grep -q "^${key}=" "${CONFIG_FILE}" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${escaped_value}|" "${CONFIG_FILE}"
    else
        echo "${key}=${value}" >> "${CONFIG_FILE}"
    fi
}

if [ ! -f "${CONFIG_FILE}" ]; then
    if [ -f "${SAVED_TEMPLATE}" ]; then
        cp "${SAVED_TEMPLATE}" "${CONFIG_FILE}"
        echo "[ha-planefence-config] First start — copied template to ${CONFIG_FILE}"
    else
        touch "${CONFIG_FILE}"
        echo "[ha-planefence-config] First start — template not found, created empty ${CONFIG_FILE}"
    fi
fi

# Warn if location placeholders were not resolved (HA location not configured).
if [ "${PF_LAT}" = "HOMEASSISTANT_LATITUDE" ] || [ "${PF_LON}" = "HOMEASSISTANT_LONGITUDE" ]; then
    echo "[ha-planefence-config] WARNING: PF_LAT/PF_LON are still placeholders."
    echo "[ha-planefence-config] Please set your Home Assistant location under"
    echo "[ha-planefence-config] Settings → System → General, or set PF_LAT/PF_LON"
    echo "[ha-planefence-config] manually in the add-on options."
fi

# Update all HA-managed keys (runs on every start, including first).
# When a value is non-empty it is written; when empty the key is left
# untouched so upstream template defaults are preserved for options that
# the user hasn't explicitly configured in the HA UI.
echo "[ha-planefence-config] Updating managed keys in ${CONFIG_FILE}"

# Helper: only call set_config when value is non-empty.
set_config_if() {
    local key="$1"
    local value="$2"
    if [ -n "$value" ]; then
        set_config "$key" "$value"
    fi
}

# ── Required: Station & Data Source ──────────────────────────────────
set_config "FEEDER_LAT"            "${PF_LAT}"
set_config "FEEDER_LONG"           "${PF_LON}"
_PF_HOST="${PF_SOCK30003HOST:-f1c878cb-adsb-multi-portal-feeder}"
set_config "PF_SOCK30003HOST"      "${_PF_HOST}"
set_config "PF_SOCK30003PORT"      "${PF_SOCK30003PORT:-30003}"

# Log resolved IP for the feeder host so misconfiguration is easy to spot
# Use || true so a failed lookup (unresolvable host or getent not in PATH)
# never causes the script to abort under set -o pipefail / set -e (bashio default).
_PF_HOST_IP=$(getent hosts "${_PF_HOST}" 2>/dev/null | awk 'NR==1{print $1}' || true)
if [ -n "${_PF_HOST_IP}" ]; then
    bashio::log.info "PF_SOCK30003HOST=${_PF_HOST} resolves to ${_PF_HOST_IP}"
else
    bashio::log.warning "PF_SOCK30003HOST=${_PF_HOST} did not resolve — check the hostname"
fi
set_config "PF_MAXDIST"            "${PF_MAXDIST:-2.0}"
set_config "PF_MAXALT"             "${PF_MAXALT:-5000}"
set_config_if "TZ"                 "${TZ:-}"

# ── General Parameters ───────────────────────────────────────────────
set_config_if "PF_DISTUNIT"        "${PF_DISTUNIT:-}"
set_config_if "PF_ALTUNIT"         "${PF_ALTUNIT:-}"
set_config_if "PF_SPEEDUNIT"       "${PF_SPEEDUNIT:-}"
set_config_if "PF_INTERVAL"        "${PF_INTERVAL:-}"
set_config_if "PF_NAME"            "${PF_NAME:-}"
set_config_if "PF_MAPURL"          "${PF_MAPURL:-}"
set_config_if "PF_MAPZOOM"         "${PF_MAPZOOM:-}"
set_config_if "PF_ELEVATION"       "${PF_ELEVATION:-}"
set_config_if "PF_FUDGELOC"        "${PF_FUDGELOC:-}"
set_config_if "PF_CHECKROUTE"      "${PF_CHECKROUTE:-}"
set_config_if "PF_TRACKSERVICE"    "${PF_TRACKSERVICE:-}"
set_config_if "PF_SHOWIMAGES"      "${PF_SHOWIMAGES:-}"
set_config_if "PF_NOISECAPT"       "${PF_NOISECAPT:-}"
set_config_if "PF_CHECKREMOTEDB"   "${PF_CHECKREMOTEDB:-}"
set_config_if "PF_DELETEAFTER"     "${PF_DELETEAFTER:-}"
set_config_if "PF_IGNOREDUPES"     "${PF_IGNOREDUPES:-}"
set_config_if "PF_COLLAPSEWITHIN"  "${PF_COLLAPSEWITHIN:-}"
set_config_if "PF_MOTD"            "${PF_MOTD:-}"
set_config_if "GENERATE_CSV"       "${GENERATE_CSV:-}"
set_config_if "OPENSKYDB_DOWNLOAD" "${OPENSKYDB_DOWNLOAD:-}"

# ── Web Page ─────────────────────────────────────────────────────────
set_config_if "PF_TABLESIZE"       "${PF_TABLESIZE:-}"
set_config_if "PF_OPENAIP_LAYER"   "${PF_OPENAIP_LAYER:-}"
set_config_if "PF_OPENAIPKEY"      "${PF_OPENAIPKEY:-}"

# ── Plane-Alert ──────────────────────────────────────────────────────
set_config_if "PF_PLANEALERT"      "${PF_PLANEALERT:-}"
set_config_if "PF_PARANGE"         "${PF_PARANGE:-}"
set_config_if "PF_PA_SQUAWKS"      "${PF_PA_SQUAWKS:-}"
set_config_if "PF_ALERTLIST"       "${PF_ALERTLIST:-}"
set_config_if "PF_ALERTHEADER"     "${PF_ALERTHEADER:-}"
set_config_if "PA_HISTTIME"        "${PA_HISTTIME:-}"
set_config_if "PA_TRACKSERVICE"    "${PA_TRACKSERVICE:-}"
set_config_if "PA_EXCLUSIONS"      "${PA_EXCLUSIONS:-}"
set_config_if "PA_TABLESIZE"       "${PA_TABLESIZE:-}"
set_config_if "PA_MOTD"            "${PA_MOTD:-}"

# ── Screenshot ───────────────────────────────────────────────────────
set_config_if "PF_SCREENSHOTURL"       "${PF_SCREENSHOTURL:-}"
set_config_if "PF_SCREENSHOT_TIMEOUT"  "${PF_SCREENSHOT_TIMEOUT:-}"

# ── Notifications - General ──────────────────────────────────────────
set_config_if "NOTIF_DATEFORMAT"   "${NOTIF_DATEFORMAT:-}"
set_config_if "PF_NOTIFEVERY"      "${PF_NOTIFEVERY:-}"
set_config_if "PF_ATTRIB"          "${PF_ATTRIB:-}"
set_config_if "PA_ATTRIB"          "${PA_ATTRIB:-}"
set_config_if "DISCORD_FEEDER_NAME" "${DISCORD_FEEDER_NAME:-}"
set_config_if "DISCORD_MEDIA"      "${DISCORD_MEDIA:-}"

# ── Discord ──────────────────────────────────────────────────────────
set_config_if "PF_DISCORD"         "${PF_DISCORD:-}"
set_config_if "PF_DISCORD_WEBHOOKS" "${PF_DISCORD_WEBHOOKS:-}"
set_config_if "PF_DISCORD_COLOR"   "${PF_DISCORD_COLOR:-}"
set_config_if "PA_DISCORD"         "${PA_DISCORD:-}"
set_config_if "PA_DISCORD_WEBHOOKS" "${PA_DISCORD_WEBHOOKS:-}"
set_config_if "PA_DISCORD_COLOR"   "${PA_DISCORD_COLOR:-}"

# ── Mastodon ─────────────────────────────────────────────────────────
set_config_if "PF_MASTODON"        "${PF_MASTODON:-}"
set_config_if "PA_MASTODON"        "${PA_MASTODON:-}"
set_config_if "MASTODON_SERVER"    "${MASTODON_SERVER:-}"
set_config_if "MASTODON_ACCESS_TOKEN" "${MASTODON_ACCESS_TOKEN:-}"
set_config_if "PF_MASTODON_VISIBILITY" "${PF_MASTODON_VISIBILITY:-}"
set_config_if "PA_MASTODON_VISIBILITY" "${PA_MASTODON_VISIBILITY:-}"
set_config_if "PA_MASTODON_MAXIMGS"    "${PA_MASTODON_MAXIMGS:-}"
set_config_if "MASTODON_RETENTION_TIME" "${MASTODON_RETENTION_TIME:-}"

# ── Telegram ─────────────────────────────────────────────────────────
set_config_if "TELEGRAM_BOT_TOKEN"     "${TELEGRAM_BOT_TOKEN:-}"
set_config_if "PF_TELEGRAM_CHAT_ID"    "${PF_TELEGRAM_CHAT_ID:-}"
set_config_if "PA_TELEGRAM_CHAT_ID"    "${PA_TELEGRAM_CHAT_ID:-}"
set_config_if "PF_TELEGRAM_ENABLED"    "${PF_TELEGRAM_ENABLED:-}"
set_config_if "PA_TELEGRAM_ENABLED"    "${PA_TELEGRAM_ENABLED:-}"
set_config_if "PF_TELEGRAM_CHAT_TYPE"  "${PF_TELEGRAM_CHAT_TYPE:-}"
set_config_if "PA_TELEGRAM_CHAT_TYPE"  "${PA_TELEGRAM_CHAT_TYPE:-}"

# ── BlueSky ──────────────────────────────────────────────────────────
set_config_if "BLUESKY_HANDLE"         "${BLUESKY_HANDLE:-}"
set_config_if "BLUESKY_APP_PASSWORD"   "${BLUESKY_APP_PASSWORD:-}"
set_config_if "PF_BLUESKY_ENABLED"     "${PF_BLUESKY_ENABLED:-}"
set_config_if "PA_BLUESKY_ENABLED"     "${PA_BLUESKY_ENABLED:-}"

# ── MQTT - Planefence ────────────────────────────────────────────────
set_config_if "PF_MQTT_URL"            "${PF_MQTT_URL:-}"
set_config_if "PF_MQTT_PORT"           "${PF_MQTT_PORT:-}"
set_config_if "PF_MQTT_TLS"            "${PF_MQTT_TLS:-}"
set_config_if "PF_MQTT_CLIENT_ID"      "${PF_MQTT_CLIENT_ID:-}"
set_config_if "PF_MQTT_TOPIC"          "${PF_MQTT_TOPIC:-}"
set_config_if "PF_MQTT_DATETIME_FORMAT" "${PF_MQTT_DATETIME_FORMAT:-}"
set_config_if "PF_MQTT_QOS"            "${PF_MQTT_QOS:-}"
set_config_if "PF_MQTT_FIELDS"         "${PF_MQTT_FIELDS:-}"
set_config_if "PF_MQTT_USERNAME"       "${PF_MQTT_USERNAME:-}"
set_config_if "PF_MQTT_PASSWORD"       "${PF_MQTT_PASSWORD:-}"

# ── MQTT - Plane-Alert ───────────────────────────────────────────────
set_config_if "PA_MQTT_URL"            "${PA_MQTT_URL:-}"
set_config_if "PA_MQTT_PORT"           "${PA_MQTT_PORT:-}"
set_config_if "PA_MQTT_TLS"            "${PA_MQTT_TLS:-}"
set_config_if "PA_MQTT_CLIENT_ID"      "${PA_MQTT_CLIENT_ID:-}"
set_config_if "PA_MQTT_TOPIC"          "${PA_MQTT_TOPIC:-}"
set_config_if "PA_MQTT_DATETIME_FORMAT" "${PA_MQTT_DATETIME_FORMAT:-}"
set_config_if "PA_MQTT_QOS"            "${PA_MQTT_QOS:-}"
set_config_if "PA_MQTT_FIELDS"         "${PA_MQTT_FIELDS:-}"
set_config_if "PA_MQTT_USERNAME"       "${PA_MQTT_USERNAME:-}"
set_config_if "PA_MQTT_PASSWORD"       "${PA_MQTT_PASSWORD:-}"

# ── RSS ──────────────────────────────────────────────────────────────
set_config_if "PF_RSS_SITELINK"        "${PF_RSS_SITELINK:-}"
set_config_if "PF_RSS_FAVICONLINK"     "${PF_RSS_FAVICONLINK:-}"
set_config_if "PA_RSS_SITELINK"        "${PA_RSS_SITELINK:-}"
set_config_if "PA_RSS_FAVICONLINK"     "${PA_RSS_FAVICONLINK:-}"

echo "[ha-planefence-config] Done."

# Set system timezone so all planefence services use the correct time
if [ -n "${TZ}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" > /etc/timezone
    echo "[ha-planefence-config] Timezone set to ${TZ}"
fi

# Signal to 00-container-startup (patched in Dockerfile) that the real
# planefence.config has been written and it is safe to proceed.
touch /run/ha-planefence-ready
echo "[ha-planefence-config] Signalled ready (/run/ha-planefence-ready)"
