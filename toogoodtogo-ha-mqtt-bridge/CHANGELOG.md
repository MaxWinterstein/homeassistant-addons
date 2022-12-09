# Changelog

## [2.4.0.1] - 2022-12-09

- Internal: Change to ghcr container registry and new build process

## [2.4.0] - 2022-08-20

- Update `toogoodtogo-ha-mqtt-bridge` to `2.4.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [2.3.0] - 2022-06-26

- Update `toogoodtogo-ha-mqtt-bridge` to `2.3.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))  
  **Note:** This introduces the new [`intense_fetch`](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/blob/main/README.md#intense_fetch-optional)

## [2.2.3] - 2022-06-19

- Update `toogoodtogo-ha-mqtt-bridge` to `2.2.3` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [2.2.2] - 2022-06-18

- Update `toogoodtogo-ha-mqtt-bridge` to `2.2.2` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))  
  **Note:** If you encounter an error around  
  `token_version = version.parse(tokens["token_version"])`  
  reinstalling the addon-on and/or starting it another time should fix the issue. See [#55](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/issues/55#)

## [2.1.0] - 2022-05-21

- Update `toogoodtogo-ha-mqtt-bridge` to `2.1.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [2.0.0] - 2022-03-05

- Update `toogoodtogo-ha-mqtt-bridge` to `2.0.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))
- Ensure login tokens are stored across reboot.
- Align Add-on version with bridge version.

## [1.9.2] - 2021-11-03

- Update `toogoodtogo-ha-mqtt-bridge` to `1.9.2` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))
- Ensure login tokens are stored across reboot.
- Align Add-on version with bridge version.

## [1.9.0] - 2021-11-15

- Update `toogoodtogo-ha-mqtt-bridge` to `1.8.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [1.8.0] - 2021-11-02

- Update `toogoodtogo-ha-mqtt-bridge` to `1.7.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases)

## [1.7.0] - 2021-10-06

- Update `toogoodtogo-ha-mqtt-bridge` to `1.6.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [1.6.0] - 2021-03-08

- Update `toogoodtogo-ha-mqtt-bridge` to `1.5.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [1.5.0] - 2021-03-06

- Update `toogoodtogo-ha-mqtt-bridge` to `1.4.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [1.4.0] - 2021-02-10

- Use Pre-build containers (no more unused docker images, yay).  
  **🚨 !!Important Update Notice!! 🚨**  
  The Update progress might fail when the installed version is <1.4.0.  
  Copy your _Configuration_ to your clipboard and Uninstall/Install manually.

## [1.3.0] - 2021-02-08

- Update `toogoodtogo-ha-mqtt-bridge` to `1.3.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [1.2.0] - 2021-02-07

- Update `toogoodtogo-ha-mqtt-bridge` to `1.2.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [1.1.0] - 2021-01-16

- Update `toogoodtogo-ha-mqtt-bridge` to `1.1.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))

## [1.0.0] - 2021-01-14

- Update `toogoodtogo-ha-mqtt-bridge` to `1.0.0` (see [release notes](https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/releases))
- Add config for the new pull interval setting `every_n_minutes`.
  **Add `every_n_minutes: 10` to your configuration! (See example config)**

## [0.1.0] - 2020-12-31

- Initial release
