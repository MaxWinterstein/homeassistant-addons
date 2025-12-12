#!/usr/bin/with-contenv bashio

# Get OS version from Supervisor API
bashio::log.info "Fetching OS info from Supervisor API..."
OS_INFO=$(curl -sf --connect-timeout 5 --max-time 10 -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    -H "Content-Type: application/json" \
    http://supervisor/os/info)

if [ -z "$OS_INFO" ]; then
  bashio::log.error "ERROR: Failed to fetch OS info from Supervisor API."
  exit 1
fi

OS_VERSION=$(echo "$OS_INFO" | jq -r '.data.version')

if [ -z "$OS_VERSION" ]; then
  bashio::log.error "ERROR: Failed to extract OS version from API response."
  exit 1
fi
bashio::log.info "OS Version: $OS_VERSION"

# Check if OS_VERSION is greater than 16
if (( $(echo "$OS_VERSION >= 16" | bc -l) )); then
    # Exclude the two variables
    bashio::log.info "OS version >= 16, not setting ulimit. Current limits:"
    ulimit -n
else
    # Export all variables
    bashio::log.info "OS version < 16, setting ulimit"
    ulimit -n 524288
fi


until [ -e /var/run/avahi-daemon/socket ]; do
  sleep 1s
done

bashio::log.info "Preparing directories"

# Only copy default config if /data/cups doesn't exist (preserves existing config on restart)
if [ ! -d /data/cups ]; then
    bashio::log.info "First run detected - copying default CUPS configuration to /data/cups"
    cp -v -R /etc/cups /data
else
    bashio::log.info "Existing CUPS configuration found in /data/cups - preserving it"
fi

rm -v -fR /etc/cups
ln -v -s /data/cups /etc/cups

bashio::log.info "Starting CUPS server as CMD from S6"

cupsd -f