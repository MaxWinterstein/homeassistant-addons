# Changelog

<!-- towncrier release notes start -->

## [1.1.0] - 2026-10-04

### Changed

- The config scripts honour an `HA_ROOT` path prefix so they can be unit-tested without a container. It is empty in production, so the real container paths are unchanged.
- Updated ghcr.io/sdr-enthusiasts/docker-planefence to v1249

### Fixed

- The startup log now reports the persistence directory actually used instead of a hard-coded one.

## [1.0.0] - 2026-03-27

### Added

- Initial release wrapping [docker-planefence](https://github.com/sdr-enthusiasts/docker-planefence) by kx1t / SDR-Enthusiasts
