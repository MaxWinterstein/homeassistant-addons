# Planefence Add-on — Claude Instructions

## Versioning

- Bump the **patch version** in `config.yaml` and `CHANGELOG.md` on **every single commit**
- Version format: `MAJOR.MINOR.PATCH` — only bump patch for fixes/tweaks, minor for new features
- The `image:` line in `config.yaml` stays **commented out** so the addon builds locally from the Dockerfile during development

## Architecture

- `export-env-from-config.sh` — sourced by cont-init; exports `/data/options.json` as env vars, resolves `HOMEASSISTANT_LATITUDE`/`LONGITUDE` placeholders via HA Supervisor API
- `rootfs/etc/cont-init.d/00-ha-planefence-config.sh` — writes resolved options into `planefence.config` before s6 services start; signals readiness via `/run/ha-planefence-ready`
- The Dockerfile patches upstream s6 scripts to wait for `/run/ha-planefence-ready` before reading config

## Shell scripting

- Scripts run under `#!/usr/bin/with-contenv bashio` which enables `set -e` and `set -o pipefail` — always add `|| true` to commands that are allowed to fail (e.g. DNS lookups, optional checks)
- Use bash string substitution (`${var//old/new}`) instead of `sed` for simple replacements inside variables
- The `set_config()` helper escapes sed-special chars (`&`, `\`, `/`) in values before substitution

## Addon hostname

- HA addon DNS hostnames use the format `{repo_hash}-{slug}` — underscores in the internal name are replaced with hyphens for valid DNS
- The ADS-B feeder default hostname is `f1c878cb-adsb-multi-portal-feeder` (hash is stable for this store's URL)
- Users with external sources (tar1090, readsb, etc.) should set `PF_SOCK30003HOST` to an IP address
