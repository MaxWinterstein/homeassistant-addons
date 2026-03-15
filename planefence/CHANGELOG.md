# Changelog

<!-- towncrier release notes start -->

## [0.1.5] - 2026-03-15

### Fixed

- Dockerfile: patch get-pa-alertlist.sh so a missing/empty PF_ALERTLIST no
  longer causes a crash loop (cat /tmp/alertlist*.txt now silently succeeds
  with empty output when no alertlist files were downloaded)
- cont-init: migration restores PF_ALERTLIST from the saved template if it
  was deleted from planefence.config by the v0.1.3 unset_config-on-empty bug

## [0.1.4] - 2026-03-15

### Fixed

- Revert set_config to write raw (unquoted) values; planefence.config is
  parsed by upstream scripts with grep/cut as well as bash source, so
  shell-quoting embedded literal quote chars in values read by those tools
- Revert set_config_if to leave keys untouched when value is empty, so
  upstream template defaults are preserved for options not set in the HA UI

## [0.1.3] - 2026-03-15

### Fixed

- Shell-quote config values in set_config so planefence.config is safe to source (spaces, $, ` etc.)
- Add curl --connect-timeout 5 --max-time 10 to HA API calls to prevent hangs
- Remove token fragments and raw coordinates from log output; use boolean/non-sensitive messages
- Make s6 ready-wait loops bounded (30s timeout, exit 1 on expiry) instead of infinite
- Mask PF_OPENAIPKEY, PF_DISCORD_WEBHOOKS, PA_DISCORD_WEBHOOKS as password? in config schema

## [0.1.2] - 2026-03-15

### Fixed

- Clear stale keys from planefence.config when options are removed in the HA UI

## [0.1.1] - 2026-03-15

### Fixed

- Pin bashio ADD with verified SHA-256 checksum

## [0.1.0] - 2026-03-15

### Added

- Initial release wrapping [docker-planefence](https://github.com/sdr-enthusiasts/docker-planefence) by kx1t / SDR-Enthusiasts
