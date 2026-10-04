# Changelog

<!-- towncrier release notes start -->

## [3.10.0] - 2026-10-04

### Changed

- Base image moved from Debian bookworm to trixie with Java 21, which Angry IP Scanner 3.10.0 requires. ([#588](https://github.com/MaxWinterstein/homeassistant-addons/issues/588))
- The add-on version now follows Angry IP Scanner's own version, hence the jump from 1.4.0.1 to 3.10.0. Add-on-only fixes get a fourth segment, e.g. 3.10.0.1.
- Updated angryip/ipscan to v3.10.0

## [1.4.0.1] - 2026-10-03

### Changed

- Base image moved from Debian bullseye (EOL) to bookworm. Rebuilds were failing because the expired `bullseye-security` repository made required packages uninstallable.

## [1.4.0.0] - 2026-01-01

### Changed

- Updated angryip/ipscan to v3.9.3 ([#396](https://github.com/MaxWinterstein/homeassistant-addons/issues/396))

## [1.2.0] - 2025-05-02

### Changed

- Updated angryip/ipscan to v3.9.1 ([#332](https://github.com/MaxWinterstein/homeassistant-addons/issues/332))

## [1.1.3] - 2022-12-07

### Internal

- Build image also for ARMv7

## [1.1.2] - 2022-12-01

### Fixed

- Permission error - part 3

## [1.1.1] - 2022-12-01

### Fixed

- Permission error - part 2

## [1.1.0] - 2022-11-29

### Fixed

- Permission error

## [1.0.0] - 2022-11-28

### Changed

- Switch to GitHub Container Registry (ghcr)

## [0.1.0] - Initial Release
