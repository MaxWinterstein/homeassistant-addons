# Changelog

## [1.24.0] - 2021-09-30

- Update `eufy-ha-mqtt-bridge` to `0.2.24` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.23.0] - 2021-09-18

- Update `eufy-ha-mqtt-bridge` to `0.2.23` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.22.0] - 2021-09-13

- Update `eufy-ha-mqtt-bridge` to `0.2.22` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.21.0] - 2021-07-31

- Update `eufy-ha-mqtt-bridge` to `0.2.21` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.20.0] - 2021-07-07

- Update `eufy-ha-mqtt-bridge` to `0.2.20` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.19.0] - 2021-07-06

- Update `eufy-ha-mqtt-bridge` to `0.2.19` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)
- Update baseimage to `7.0.2`

## [1.18.0] - 2021-04-23

- Update `eufy-ha-mqtt-bridge` to `0.2.18` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.17.0] - 2021-04-21

- Update `eufy-ha-mqtt-bridge` to `0.2.16` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.16.1] - 2021-04-21

- Fixed bug in configuration. (see [issue](https://github.com/matijse/eufy-ha-mqtt-bridge/issues/62))

## [1.16.0] - 2021-04-20

- Update `eufy-ha-mqtt-bridge` to `0.2.15` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.15.0] - 2021-04-14

- Update `eufy-ha-mqtt-bridge` to `0.2.14` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.14.0] - 2021-04-08

- Update `eufy-ha-mqtt-bridge` to `0.2.13` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.13.0] - 2021-03-06

- Update `eufy-ha-mqtt-bridge` to `0.2.12` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.12.0] - 2021-03-06

- Introduce new `eval` options
- Do no longer store `/data` inside `share` folder

## [1.11.0] - 2021-02-15

- Update `eufy-ha-mqtt-bridge` to `0.2.11` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.10.0] - 2021-02-14

- Use Pre-build containers (no more unused docker images, yay).  
  **🚨 !!Important Update Notice!! 🚨**  
  The Update progress might fail when the installed version is <1.10.0.  
  Copy your _Configuration_ to your clipboard and Uninstall/Install manually.

## [1.9.0] - 2021-02-05

- Update `eufy-ha-mqtt-bridge` to `0.2.10` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)
- Add new configration option `mqtt.keepalive`

## [1.8.0] - 2021-01-28

- Update `eufy-ha-mqtt-bridge` to `0.2.9` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.7.0] - 2021-01-27

- Update `eufy-ha-mqtt-bridge` to `0.2.8` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.6.0] - 2021-01-25

- Update `eufy-ha-mqtt-bridge` to `0.2.7` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.5.0] - 2021-01-25

- Update `eufy-ha-mqtt-bridge` to `0.2.6` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.4.0] - 2021-01-23

- Update `eufy-ha-mqtt-bridge` to `0.2.5` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.3.0] - 2021-01-22

- Update `eufy-ha-mqtt-bridge` to `0.2.4` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.2.0] - 2021-01-21

- Update `eufy-ha-mqtt-bridge` to `0.2.3` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.1.0] - 2021-01-11

- Update `eufy-ha-mqtt-bridge` to `0.2.1` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [1.0.0] - 2021-01-10

- Switch from `main` branch to releases from `eufy-ha-mqtt-bridge`
- Update `eufy-ha-mqtt-bridge` to `0.2.0` [Changelog](https://github.com/matijse/eufy-ha-mqtt-bridge/releases)

## [0.7.0] - 2021-01-05

- Moved to dockerhub located images
- Updated logo

## [0.6.0] - 2021-01-02

- Add `hassio_role` and `hassio_api` to config to prevent error message

## [0.5.0] - 2021-01-02

- Improve image recration by adding some cache buster
- Change to bashio logs
- Add `log_level` cofiguration option
- Add schema validation to configuration
- Add some build date information

## [0.4.0] - 2021-01-02

- Change base image to `hassioaddons/debian-base`
- Add icon (thx to [davida72](https://github.com/matijse/eufy-ha-mqtt-bridge/issues/1#issuecomment-753333591]))

## [0.3.0] - 2020-12-31

- Change name from **eufy-ha-mqtt-bridge** to **Eufy Home Assistant MQTT Bridge**

## [0.2.0] - 2020-12-31

- Remove superflous `apt-get` part
- Added some 'do not edit' note to config.yml
- Added some note about the rebuild button
- Dirtypatched log level for console output

## [0.1.0] - 2020-12-31

- Initial release
