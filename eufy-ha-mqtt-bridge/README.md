# Home Assistant Add-on: Eufy Home Assistant MQTT Bridge

---
## 🚨 This is some experimental release! 🚨
---

**As this add-on will be build locally it might take some time (8min on my rpi4). This will be solved by pre-build images soon.**

Quick wrapp around https://github.com/matijse/eufy-ha-mqtt-bridge.

Application data will be written to `/share/eufy-ha-mqtt-bridge/` so log and other files can be accessed from other addons, e.g. the `Samba share` addon, or view it at the `Visual Studio Code` add-on.  

As there is currently no real versioning you might want to hit the `REBUILD` button from time to time, to ensure you got the latest version.

🚨 This also contains some plaintext configuration file with login credentials, so take care who can access your files! 🚨