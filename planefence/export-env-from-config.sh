#!/usr/bin/with-contenv bashio
#
# Reads the Home Assistant Add-On configuration from /data/options.json
# and exports all values as environment variables.
# Replaces HOMEASSISTANT_LATITUDE / HOMEASSISTANT_LONGITUDE placeholders
# with actual values from HA via bashio.
#
# This script must be sourced (. /export-env-from-config.sh)
# The with-contenv shebang is ignored when sourced — the CALLER must
# use #!/usr/bin/with-contenv bashio so SUPERVISOR_TOKEN and bashio
# functions are available.

# Only run once per process to avoid re-sourcing overhead
if [ -n "${_HA_CONFIG_EXPORTED:-}" ]; then
    return 0
fi
export _HA_CONFIG_EXPORTED=1

if [ ! -f '/data/options.json' ]; then
    bashio::log.error "export-env: /data/options.json not found"
    return 1
fi

# Check if options.json actually contains HOMEASSISTANT_* placeholders that need resolving.
# If PF_LAT/PF_LON are already real coordinates, skip the API entirely.
_HA_LAT=""
_HA_LON=""
_HA_NEEDS_RESOLVE=false

if grep -q 'HOMEASSISTANT_LATITUDE\|HOMEASSISTANT_LONGITUDE' /data/options.json 2>/dev/null; then
    _HA_NEEDS_RESOLVE=true
fi

if [ "$_HA_NEEDS_RESOLVE" = true ]; then
    # Fetch coordinates from HA via bashio.
    # HA Core may not be ready when the addon starts, so retry a few times.
    _HA_MAX_RETRIES=10
    _HA_RETRY_DELAY=3

    bashio::log.info "export-env: options.json contains HOMEASSISTANT_* placeholders — resolving via HA Core API"
    if [ -n "${SUPERVISOR_TOKEN}" ]; then
        bashio::log.info "export-env: SUPERVISOR_TOKEN is set"
    else
        bashio::log.warning "export-env: SUPERVISOR_TOKEN is not set"
    fi

    for _attempt in $(seq 1 $_HA_MAX_RETRIES); do
        bashio::log.info "export-env: Attempt ${_attempt}/${_HA_MAX_RETRIES}: GET /core/api/config"

        # Use curl with SUPERVISOR_TOKEN (loaded by with-contenv) to hit HA Core API
        if _HA_CONFIG=$(curl -sSf --connect-timeout 5 --max-time 10 \
            -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
            http://supervisor/core/api/config 2>&1); then
            _HA_LAT=$(echo "$_HA_CONFIG" | jq -r '.latitude // empty')
            _HA_LON=$(echo "$_HA_CONFIG" | jq -r '.longitude // empty')

            if [ -n "$_HA_LAT" ] && [ -n "$_HA_LON" ]; then
                bashio::log.info "export-env: Home Assistant coordinates configured"
                break
            fi
            bashio::log.warning "export-env:   lat/lon empty in response"
        else
            bashio::log.warning "export-env:   API request failed: ${_HA_CONFIG:-no output}"
            _HA_LAT=""
            _HA_LON=""
        fi

        if [ "$_attempt" -lt "$_HA_MAX_RETRIES" ]; then
            bashio::log.info "export-env:   Retrying in ${_HA_RETRY_DELAY}s..."
            sleep "$_HA_RETRY_DELAY"
        fi
    done

    if [ -z "$_HA_LAT" ] || [ -z "$_HA_LON" ]; then
        bashio::log.error "export-env: Could not resolve HA location after ${_HA_MAX_RETRIES} attempts."
        bashio::log.error "export-env: HOMEASSISTANT_LATITUDE/LONGITUDE placeholders will NOT be replaced."
        bashio::log.error "export-env: Fix: Set location under Settings → System → General,"
        bashio::log.error "export-env:   or set PF_LAT/PF_LON to numeric values in the addon options."
    fi
else
    bashio::log.info "export-env: PF_LAT/PF_LON already set to coordinates — skipping Supervisor API"
fi

# Export all options as environment variables, replacing HA placeholders
bashio::log.info "export-env: Exporting options from /data/options.json:"
while read -rd $'' line; do
    if [[ $line == *"HOMEASSISTANT_LATITUDE"* ]]; then
        if [ -n "$_HA_LAT" ]; then
            bashio::log.info "export-env:   ${line%%=*}: replaced HOMEASSISTANT_LATITUDE placeholder"
            line="${line//HOMEASSISTANT_LATITUDE/$_HA_LAT}"
        else
            bashio::log.warning "export-env:   ${line%%=*}: keeping unresolved HOMEASSISTANT_LATITUDE"
        fi
    fi
    if [[ $line == *"HOMEASSISTANT_LONGITUDE"* ]]; then
        if [ -n "$_HA_LON" ]; then
            bashio::log.info "export-env:   ${line%%=*}: replaced HOMEASSISTANT_LONGITUDE placeholder"
            line="${line//HOMEASSISTANT_LONGITUDE/$_HA_LON}"
        else
            bashio::log.warning "export-env:   ${line%%=*}: keeping unresolved HOMEASSISTANT_LONGITUDE"
        fi
    fi
    bashio::log.info "export-env:   export ${line%%=*}=***"
    export "$line"
done < <(jq -r 'to_entries | map("\(.key)=\(.value)\u0000")[]' /data/options.json)
bashio::log.info "export-env: Done."
