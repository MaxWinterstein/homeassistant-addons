#!/usr/bin/with-contenv bashio

bashio::log.info "Copy setings file"
cp /data/options.json /app/toogoodtogo_ha_mqtt_bridge/settings.local.json

if ! bashio::fs.file_exists /data/tokens.json; then
    bashio::log.magenta "No saved tokens found. "
    bashio::log.magenta "Please make sure to check your email for the login request and answer quickly."
    bashio::log.magenta "You can't open it on a mobile phone where the TGTG app itself is installed."
else
    bashio::log.cyan "Saved tokens found."
    bashio::log.cyan "If you encoure problems reinstalling the add-on might help."
fi
