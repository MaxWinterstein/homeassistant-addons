# Changelog

<!-- towncrier release notes start -->

## [2.8.0.1] - 2026-10-04

### Fixed

- Now really based on fr24feed-piaware 2.8.0 (fr24feed 1.0.56). The 2.8.0 release only updated the unused Dockerfile default, so its images were still built on 2.6.1 (fr24feed 1.0.54).

## [2.8.0] - 2026-10-04

### Changed

- Updated thomx/fr24feed-piaware to v2.8.0

### Fixed

- Builds work again: the upstream image is still Debian bullseye (EOL), so apt now fetches its security updates from archive.debian.org. ([#532](https://github.com/MaxWinterstein/homeassistant-addons/issues/532))
- A failed Flightradar24 signup is now reported as a failure. The exit code was read from `tee` rather than from the signup wizard, so every run logged success regardless of what actually happened. ([#580](https://github.com/MaxWinterstein/homeassistant-addons/issues/580))

## [2.6.1] - 2026-03-14

### Changed

- Updated thomx/fr24feed-piaware to v2.6.1 ([#501](https://github.com/MaxWinterstein/homeassistant-addons/issues/501))

## [0.5.0] - 2026-01-02

### Changed

- Updated thomx/fr24feed-piaware to v2.6.0 ([#462](https://github.com/MaxWinterstein/homeassistant-addons/issues/462))

## [0.4.0] - 2025-08-28

### Changed

- Updated thomx/fr24feed-piaware to v2.5.0 ([#400](https://github.com/MaxWinterstein/homeassistant-addons/issues/400))

## [0.3.0] - 2025-08-03

- Fix negative lat/long not working

## [0.2.0] - 2025-06-26

- Fix config parsing

## [0.1.0] - Initial Release
