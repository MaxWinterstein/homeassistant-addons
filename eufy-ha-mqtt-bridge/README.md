# Home Assistant Add-on: Eufy Home Assistant MQTT Bridge
## Based on https://github.com/matijse/eufy-ha-mqtt-bridge/

---
## 🚨 This is some experimental release! 🚨
---

**The underlaying docker image will be build every night until there is some kind of versioning available.**
**If a feature was released at eufy-ha-mqtt-bridge, it might be available as recently as the next day.**

Quick wrapp around https://github.com/matijse/eufy-ha-mqtt-bridge.

Application data will be written to `/share/eufy-ha-mqtt-bridge/` so log and other files can be accessed from other addons, e.g. the `Samba share` addon, or view it at the `Visual Studio Code` add-on.  

As there is currently no real versioning you might want to hit the `REBUILD` button from time to time, to ensure you got the latest version.

🚨 This also contains some plaintext configuration file with login credentials, so take care who can access your files! 🚨

## ♥
- [@matijse](https://github.com/matijse/) for coding this awesome bridge
- [@davida72](https://github.com/matijse/eufy-ha-mqtt-bridge/issues/1#issuecomment-753333591]) for the awesome icon