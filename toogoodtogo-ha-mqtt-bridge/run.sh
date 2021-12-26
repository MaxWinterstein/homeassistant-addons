#!/usr/bin/env bashio

bashio::log.info "Copy setings file"
cp /data/options.json /app/toogoodtogo_ha_mqtt_bridge/settings.local.json

bashio::log.info "Strating Bridge"
python toogoodtogo_ha_mqtt_bridge/main.py
