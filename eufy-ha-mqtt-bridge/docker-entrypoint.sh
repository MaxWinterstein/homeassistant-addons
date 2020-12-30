#!/bin/sh
set -e

echo "Symlinking data dir"
mkdir -p /share/eufy-ha-mqtt-bridge/data
rm -rfv /app/data
ln -s /share/eufy-ha-mqtt-bridge/data /app # symlink data mount from share 

echo "exporting environment vars form options file"
/app/node_modules/.bin/json2yml /data/options.json > /app/data/config.yml

echo "starting original stuff..."
exec npm run start