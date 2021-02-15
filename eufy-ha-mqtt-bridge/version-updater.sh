#!/bin/bash
echo "Fetching eufy-ha-mqtt-bridge version"
MQTT_BRIDGE_VERSION=$(curl -s https://api.github.com/repos/matijse/eufy-ha-mqtt-bridge/releases/latest | grep tag_name | cut -d : -f 2,3 | tr -d \" | tr -d ',' | tr -d ' ')
echo "Newest version of eufy-ha-mqtt-bridge: $MQTT_BRIDGE_VERSION"
echo "MQTT_BRIDGE_VERSION=$MQTT_BRIDGE_VERSION" >> $GITHUB_ENV

echo "Check if $MQTT_BRIDGE_VERSION is already used..."
grep "ARG VERSION=${MQTT_BRIDGE_VERSION}" Dockerfile && { echo "Version is the same, nothing to do"; exit 0; } || echo "Version is different, will continue..."
echo "CONTINUE=true" >> $GITHUB_ENV; 

echo "Reading current addon version"
ADDON_CURR_VERSION=$(grep version config.json | cut -d '"' -f 4)
ADDON_NEXT_VERSION=$(echo $ADDON_CURR_VERSION| perl -pe 's/(\d+\.)(\d+)(.*)/$1.($2+1).".0"/e')
echo "ADDON_NEXT_VERSION=$ADDON_NEXT_VERSION" >> $GITHUB_ENV
echo "Update config..."
sed -i.bak "s|\ \ \"version\": \".*$|\ \ \"version\": \"$ADDON_NEXT_VERSION\",|" config.json

echo "Update Dockerfile..."
sed -i.bak "s|VERSION=.*$|VERSION=${MQTT_BRIDGE_VERSION}|" Dockerfile

echo "Update CHANGELOG..."
sed -i.bak "2 a ## [${ADDON_NEXT_VERSION}] - $(date +%Y-%m-%d)" CHANGELOG.md
sed -i.bak "3 a - Update \`eufy-ha-mqtt-bridge\` to \`${MQTT_BRIDGE_VERSION}\` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)\n" CHANGELOG.md

rm *.bak #cleanup, mac os related problem