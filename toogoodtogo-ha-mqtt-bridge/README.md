# Home Assistant Add-on: TooGoodToGo Home Assistant MQTT Bridge
## Based on https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge

---
## 🚨 This is some experimental release! 🚨
---

Example Config:
```toml
mqtt:
  host: homeassistant
  port: 1883
  username: mqtt
  password: mqtt
tgtg:
  email: me@example.ocm
  password: iliketurtles
  every_n_minutes: 10
timezone: Europe/Berlin
locale: en_us
```