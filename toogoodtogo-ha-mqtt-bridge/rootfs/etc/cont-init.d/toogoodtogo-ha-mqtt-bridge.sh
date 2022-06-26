#!/usr/bin/with-contenv bashio

bashio::log.info "Copy settings file"
cp /data/options.json /app/toogoodtogo_ha_mqtt_bridge/settings.local.json

# as HA add-ons only support config files 2 levels in depth we need to to some alignment of 'intense_fetch'
jq ".tgtg += { intense_fetch: { interval: .tgtg.intense_fetch_interval, period_of_time: .tgtg.intense_fetch_period_of_time}}" /app/toogoodtogo_ha_mqtt_bridge/settings.local.json > /app/toogoodtogo_ha_mqtt_bridge/settings.local.json.tmp
mv /app/toogoodtogo_ha_mqtt_bridge/settings.local.json.tmp /app/toogoodtogo_ha_mqtt_bridge/settings.local.json

if ! bashio::fs.file_exists /data/tokens.json; then 
    bashio::log.magenta "No saved tokens found."
    bashio::log.magenta "Please make sure to check your email for the login request and answer quickly."
    bashio::log.magenta "You can't open it on a mobile phone where the TGTG app itself is installed."
else
    bashio::log.cyan "Saved tokens found."
    bashio::log.cyan "If you have any problems reinstalling the add-on might help."
fi