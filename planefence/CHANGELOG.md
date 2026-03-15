# Changelog

<!-- towncrier release notes start -->

## [0.1.4] - 2026-03-15

### Changed

- All config option names in the HA UI now include the config key in parentheses (e.g. "Fence radius (PF_MAXDIST)") so users can find settings by searching for the variable name

## [0.1.3] - 2026-03-15

### Fixed

- `PF_NOTIFEVERY`, `PF_CHECKROUTE`, and `PF_SHOWIMAGES` schema changed from `list(ON|OFF)` / `str` to `bool` — upstream config uses `true`/`false` for these

## [0.1.2] - 2026-03-15

### Fixed

- `PF_NOISECAPT` schema corrected from `list(ON|OFF)` to `str` (it is a URL, not a toggle)
- Added missing `PA_SILHOUETTES_LINK` to schema, translations, and cont-init config writer

## [0.1.1] - 2026-03-15

### Added

- Auto-populate `TZ` from Home Assistant timezone via Supervisor API using `HOMEASSISTANT_TIMEZONE` placeholder

## [0.1.0] - 2026-03-15

### Added

- Initial release wrapping [docker-planefence](https://github.com/sdr-enthusiasts/docker-planefence) by kx1t / SDR-Enthusiasts
