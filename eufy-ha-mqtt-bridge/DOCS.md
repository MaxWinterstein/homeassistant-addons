# Home Assistant Add-on: Eufy Home Assistant MQTT Bridge

## Configuration
### `eval` (string)
Allows to pass some bash commands to run every time before the start of the bridge.

Multi-line commands are possible but must end with `;`. See examples below.

You might want to disable this after a run.

*Only use when you know what you are doing!*


#### Example: Symlink data dir to `shares`
```yaml
eval: |
  bashio::log.info "Symlinking data dir";
  mkdir -p /share/eufy-ha-mqtt-bridge/data;
  rm -rf /app/data;
  ln -s /share/eufy-ha-mqtt-bridge/data /app;
```

#### Example: Export payloads to file 
To help adding more devices it is crucial to provide some information, see https://github.com/matijse/eufy-ha-mqtt-bridge/issues/7.

```yaml
eval: >
  sqlite3 -csv /app/data/database.sqlite "SELECT "'*'" FROM push_payloads" >
  /share/export.csv
```

*Note:* Asterisk must be removed from the double quotes.