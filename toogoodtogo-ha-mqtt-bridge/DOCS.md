# Home Assistant Add-on: TooGoodToGo Home Assistant MQTT Bridge

## Configuration

Example Config:

```yaml
mqtt:
  host: homeassistant
  port: 1883
  username: mqtt
  password: mqtt
tgtg:
  email: me@example.com
  language: en-US
  polling_schedule: "*/10 * * * *"
  intense_fetch_interval: 30
  intense_fetch_period_of_time: 5
timezone: Europe/Berlin
locale: en_us
cleanup: true
```

See https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge for more configuration options.
