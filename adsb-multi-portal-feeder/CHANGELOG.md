# Changelog

<!-- towncrier release notes start -->

## [1.32.1] - 2024-04-18

- Update `thomx/fr24feed-piaware` to `1.32.1` see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.32.1) for more

## [1.32.0] - 2023-10-30

- Update `thomx/fr24feed-piaware` to `1.32.0` see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.32.0) for more

## [1.30.0] - 2023-10-30

- Update `thomx/fr24feed-piaware` to `1.30.0` see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.30.0) for more

## [1.29.1] - 2023-10-30

- Update `thomx/fr24feed-piaware` to `1.29.1` that brings ADSBHub support - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.28.0) for more

## [1.27.2.1] - 2023-07-17

- Update [adsb-hassio-sensors](https://github.com/plo53/adsb-hassio-sensors) to `1.1.2-1` that brings more aircraft sensors - see INFO and [their repo](https://github.com/plo53/adsb-hassio-sensors) for more

## [1.27.2] - 2023-07-09

- Update `thomx/fr24feed-piaware` to `1.27.2` that fixes RadarBox mlat support - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.27.2) for more

## [1.27.1.1] - 2023-07-09

- Update `thomx/fr24feed-piaware` to `1.27.1` that fixes RadarBox mlat support - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.27.1) for more
- Update [adsb-hassio-sensors](https://github.com/plo53/adsb-hassio-sensors) to `1.1.1` that brings more aircraft sensors - see INFO and [their repo](https://github.com/plo53/adsb-hassio-sensors) for more

## [1.27.0] - 2023-06-24

- Update `thomx/fr24feed-piaware` to `1.27.0` that brings RadarBox support - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.27.0) for more
- Add [adsb-hassio-sensors](https://github.com/plo53/adsb-hassio-sensors) that brings aircraft sensors - see INFO and [#172](https://github.com/MaxWinterstein/homeassistant-addons/issues/172) for more

## [1.26.1] - 2023-06-21

- Update `thomx/fr24feed-piaware` to `1.26.1` that brings adsb.fi support - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.26.1) for more

## [1.25.0] - 2023-06-09

- This release changes to settings properties: `ULIMIT_N` and `FR24FEED_ULIMIT_N` have been renamed at upstream, they are now prefixed with `SYSTEM_`.
  If you have them configured before, you might need to fix your configuration. Sorry.
- Update `thomx/fr24feed-piaware` to `1.25.0` - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.25.0) for more

## [1.24.0.1] - 2023-06-08

- Add missing HTML_DEFAULT_TRACKER (the typo OpenskyNetowrk is intended) - see [#149](https://github.com/MaxWinterstein/homeassistant-addons/issues/163) for more

## [1.24.0] - 2023-06-07

- Update `thomx/fr24feed-piaware` to `1.24.0` that brings Opensky support - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.24.0) for more

## [1.23.0] - 2023-06-05

- Add default value for `ULIMIT_N` and add as configuration option, as the default was removed in the upstream - see [#119](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/issues/119) for more
- Add new configuration option for `ulimit -n` at FR24Feed `FR24FEED_ULIMIT_N`.
  Rolled the dice and deceided to start with 1024, very open for better values - see [#151](https://github.com/MaxWinterstein/homeassistant-addons/issues/151) for more
- Update `thomx/fr24feed-piaware` to `1.23.0` - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.23.0) for more

## [1.21.0] - 2023-04-27

- Remove my memory fix and update to `1.21.0` which includes it - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.21.0) for more

## [1.20.3] - 2023-04-21

- Fix memory consumption issue for _Home Assistant OS 10_ / _Docker v23_ - - see [#149](https://github.com/MaxWinterstein/homeassistant-addons/issues/149) for more

## [1.20.2] - 2023-04-20

- Fix memory consumption issue for _Home Assistant OS 10_ / _Docker v23_ - - see [#149](https://github.com/MaxWinterstein/homeassistant-addons/issues/149) for more

## [1.20.0] - 2023-02-08

- Update `thomx/fr24feed-piaware` to `1.20.0` - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.20.0) for more

## [1.19.0] - 2023-01-20

- Update `thomx/fr24feed-piaware` to `1.19.0` - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.19.0) for more

## [1.18.0.2] - 2022-12-07

- Internal: Build image also for ARMv7

## [1.18.0.1] - 2022-12-07

- Internal: Change to ghcr container registry and new build process

## [1.18.0] - 2022-11-25

- Update `thomx/fr24feed-piaware` to `1.18.0` - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.18.0) for more
- Change from local built images to hosted images - this requires a recent HomeAssistant Supervisor - see [#58](https://github.com/MaxWinterstein/homeassistant-addons/issues/58) for more.

## [1.17.0] - 2022-06-29

- Update `thomx/fr24feed-piaware` to `1.17.0` - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.17.0) for more

## [1.15.0] - 2021-05-24

- Update `thomx/fr24feed-piaware` to `1.15.0` - see [their release notes](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090/releases/tag/1.15.0) for more

## [1.0.3] - 2021-03-29

- Introduce magic variables (`HOMEASSISTANT_LATITUDE`, `HOMEASSISTANT_LONGITUDE`, `HOMEASSISTANT_ELEVATION`)
- Optimize config schema

## [1.0.2] - 2021-03-29

- Fix typ0 in config template, should be `MLAT_EXACT_LON` instead `MLAT_EXACT_LONG`.  
  Thx again to [@Delta1977](https://github.com/Delta1977)

## [1.0.1] - 2021-03-28

- Add port for plane finder status page

## [1.0.0] - 2021-03-28

- Update to 1.12.0 (now with planefinder support)
- Allow configuration options containing whitespaces

## [0.1.37] - 2021-03-18

- Update to 1.10.1 - now with adsbexchange support. See [#67](https://github.com/MaxWinterstein/homeassistant-addons/issues/67#).  
  Thx to [@Delta1977](https://github.com/Delta1977) for his work ❤️

## [0.1.36] - 2021-01-03

- Update to 1.9.0

## [0.1.32] - 2021-01-03

- Initial release
