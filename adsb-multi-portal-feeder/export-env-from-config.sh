#!/bin/bash
#
# As Home Assistant parses the Add-On configuration towards /data/options.json 
# we want all its values as environment variables.
#
# This needs to be sourced ($ source $0)

# Logging enabled flag (set to 1 to enable, 0 to disable)
LOGGING_ENABLED=0

# Log function
log() {
  if [[ "$LOGGING_ENABLED" -eq 1 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >&2  # Log to stderr with timestamp
  fi
}

# Get OS version from Supervisor API
log "Fetching OS info from Supervisor API..."
OS_INFO=$(curl -sf --connect-timeout 5 --max-time 10 -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    -H "Content-Type: application/json" \
    http://supervisor/os/info)

if [ -z "$OS_INFO" ]; then
  log "ERROR: Failed to fetch OS info from Supervisor API."
  exit 1
fi

OS_VERSION=$(echo "$OS_INFO" | jq -r '.data.version')

if [ -z "$OS_VERSION" ]; then
  log "ERROR: Failed to extract OS version from API response."
  exit 1
fi
log "OS Version: $OS_VERSION"

# Check if OS_VERSION is greater than 16
if (( $(echo "$OS_VERSION >= 16" | bc -l) )); then
    # Exclude the two variables
    log "OS version >= 16, excluding SYSTEM_HTTP_ULIMIT_N and SYSTEM_FR24FEED_ULIMIT_N"
    jq_filter='to_entries | map(select(.key != "SYSTEM_HTTP_ULIMIT_N" and .key != "SYSTEM_FR24FEED_ULIMIT_N")) | map("\(.key)=\(.value)\u0000")[]'
else
    # Export all variables
    log "OS version < 16, exporting all variables"
    jq_filter='to_entries | map("\(.key)=\(.value)\u0000")[]'
fi

CONFIG=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" -H "Content-Type: application/json" http://supervisor/core/api/config)
LAT=$(echo $CONFIG | jq '.latitude')
LON=$(echo $CONFIG | jq '.longitude')
ELE=$(echo $CONFIG | jq '.elevation')

# TODO: Find a way to use bashio and source together

if [ ! -f '/data/options.json' ]; then
     echo 'ERROR: /data/options.json not found' >>/dev/stderr
     exit 1
fi

# export add-on configuration so it can be sourced and used as env vars later
# thx https://stackoverflow.com/a/48513046/635876
while read -rd $'' line
do
    if [[ $line == *"HOMEASSISTANT_LATITUDE" ]] || [[ $line == *"HOMEASSISTANT_LONGITUDE" ]] || [[ $line == *"HOMEASSISTANT_ELEVATION" ]]; then
        line=$(echo $line | sed "s/HOMEASSISTANT_LATITUDE/$LAT/")
        line=$(echo $line | sed "s/HOMEASSISTANT_LONGITUDE/$LON/")
        line=$(echo $line | sed "s/HOMEASSISTANT_ELEVATION/$ELE/")
    fi
    # echo $line
    export "$line"
done < <(jq -r "$jq_filter" /data/options.json)
