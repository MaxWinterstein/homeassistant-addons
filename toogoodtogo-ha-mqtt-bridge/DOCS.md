# Home Assistant Add-on: TooGoodToGo Home Assistant MQTT Bridge

## Configuration

Example Config:

```toml
mqtt:
  host: homeassistant
  port: 1883
  username: mqtt
  password: mqtt
tgtg:
  email: me@example.com
  language: en-US
  polling_schedule: "*/10 * * * *"
timezone: Europe/Berlin
locale: en_us
```

See https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge for more configuration options.
