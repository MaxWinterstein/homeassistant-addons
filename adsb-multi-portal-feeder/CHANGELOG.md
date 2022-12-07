# Changelog

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
