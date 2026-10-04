# Changelog

<!-- towncrier release notes start -->

## [1.1.1] - 2026-10-04

### Changed

- Updated ghcr.io/sdr-enthusiasts/docker-planefence to v1251

### Fixed

- Fresh installs work again: the add-on now also writes the longitude as FEEDER_LON, the name docker-planefence uses since latest-build-1249. Before, a new install kept the template's placeholder longitude and Planefence stopped with "SETUP REQUIRED".
- PF_PLANEALERT is honoured again on fresh installs; the new upstream template's PLANEALERT=ON no longer overrides it.

## [1.1.0] - 2026-10-04

### Changed

- The config scripts honour an `HA_ROOT` path prefix so they can be unit-tested without a container. It is empty in production, so the real container paths are unchanged.
- Updated ghcr.io/sdr-enthusiasts/docker-planefence to v1249

### Fixed

- The startup log now reports the persistence directory actually used instead of a hard-coded one.

## [1.0.0] - 2026-03-27

### Added

- Initial release wrapping [docker-planefence](https://github.com/sdr-enthusiasts/docker-planefence) by kx1t / SDR-Enthusiasts
