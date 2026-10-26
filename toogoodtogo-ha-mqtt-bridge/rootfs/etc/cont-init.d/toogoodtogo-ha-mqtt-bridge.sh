#!/usr/bin/with-contenv bashio

bashio::log.info "Copy settings file"
cp /data/options.json /app/toogoodtogo_ha_mqtt_bridge/settings.local.json

# as HA add-ons only support config files 2 levels in depth we need to to some alignment of 'intense_fetch'
jq ".tgtg += { intense_fetch: { interval: .tgtg.intense_fetch_interval, period_of_time: .tgtg.intense_fetch_period_of_time}}" /app/toogoodtogo_ha_mqtt_bridge/settings.local.json > /app/toogoodtogo_ha_mqtt_bridge/settings.local.json.tmp
mv /app/toogoodtogo_ha_mqtt_bridge/settings.local.json.tmp /app/toogoodtogo_ha_mqtt_bridge/settings.local.json

# The bridge serves its login page for the emailed PIN on the ingress port (config.yaml
# ingress_port). The page itself has no authentication, so only Home Assistant's ingress
# proxy may reach it; ingress already requires a logged-in Home Assistant user.
jq '.login_portal = {enabled: true, port: 8099, allowed_ips: ["172.30.32.2"]}' /app/toogoodtogo_ha_mqtt_bridge/settings.local.json > /app/toogoodtogo_ha_mqtt_bridge/settings.local.json.tmp
mv /app/toogoodtogo_ha_mqtt_bridge/settings.local.json.tmp /app/toogoodtogo_ha_mqtt_bridge/settings.local.json

if ! bashio::fs.file_exists /data/tokens.json; then 
    bashio::log.magenta "No saved tokens found."
    bashio::log.magenta "Too Good To Go will email you a login PIN. Open this add-on's Web UI and enter it there."
else
    bashio::log.cyan "Saved tokens found."
    bashio::log.cyan "If Too Good To Go rejects them, the add-on asks for a new PIN in its Web UI."
fi