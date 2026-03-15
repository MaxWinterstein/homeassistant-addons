# ✈️ Planefence Add-on

[![Open your Home Assistant instance and show the add-on page.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=planefence&repository_url=https%3A%2F%2Fgithub.com%2FMaxWinterstein%2Fhomeassistant-addons)

Track aircraft flying near your ADS-B receiver. Planefence logs low-altitude and nearby aircraft, generates noise statistics, and can send alerts via Discord, Mastodon, Telegram, and BlueSky.

This add-on wraps [docker-planefence](https://github.com/sdr-enthusiasts/docker-planefence) by kx1t / SDR-Enthusiasts.

## Requirements

Before any data appears, two things must be in place:

### 📡 1. ADS-B data source

Planefence reads aircraft data in BaseStation/SBS format from a TCP port `30003` source. Options:

- **[ADS-B Multi-Portal Feeder](https://github.com/MaxWinterstein/homeassistant-addons)** from this repo — zero configuration needed, the default hostname points to it automatically.
- **Any other SBS source** (e.g. a [tar1090](https://github.com/sdr-enthusiasts/docker-tar1090) instance, readsb, dump1090) — set `PF_SOCK30003HOST` to its IP address.

> **About addon hostnames:** HA addons address each other using the format `{repo_hash}-{slug}` (e.g. `f1c878cb-adsb-multi-portal-feeder`). The repo hash is the same for everyone installing from this store, and the underscore between hash and slug is replaced with a hyphen for valid DNS. This only works between addons from the same store — for external sources use an IP address.

### 📍 2. Station location

Planefence needs your coordinates to know which aircraft are "nearby". By default these are read automatically from your Home Assistant location settings. If that is not configured, set `PF_LAT` and `PF_LON` manually in the add-on options.

## ⚙️ Configuration

| Option             | Default                             | Description                                               |
| ------------------ | ----------------------------------- | --------------------------------------------------------- |
| `PF_SOCK30003HOST` | `f1c878cb-adsb-multi-portal-feeder` | Hostname or IP of your ADS-B data source (SBS/port 30003) |
| `PF_SOCK30003PORT` | `30003`                             | SBS output port                                           |
| `PF_LAT`           | HA latitude                         | Station latitude (auto-filled from Home Assistant)        |
| `PF_LON`           | HA longitude                        | Station longitude (auto-filled from Home Assistant)       |
| `PF_MAXDIST`       | `2.0`                               | Maximum distance from station (nautical miles)            |
| `PF_MAXALT`        | `5000`                              | Maximum altitude (feet)                                   |
| `TZ`               | `UTC`                               | Timezone, e.g. `Europe/Berlin`                            |

### Advanced configuration

On first start the add-on copies the full upstream config template to `addon_configs/planefence/planefence.config`. This file contains every available option with inline comments — edit it directly for anything not covered by the UI above (alerts, filtering, map customisation, and more). See the [upstream documentation](https://github.com/sdr-enthusiasts/docker-planefence) for details.

**The add-on only ever overwrites the options listed in the table above.** Everything else you set manually will survive restarts.

> **Tip:** The [Studio Code Server add-on](https://github.com/hassio-addons/addon-vscode) lets you edit `addon_configs/planefence/planefence.config` directly from your browser.

## 🌐 Web UI

Once aircraft are being received, the Planefence web interface is available via the **Open Web UI** button on the add-on page, or the sidebar panel. It may take a few minutes after the first start before entries appear.

---

> **Disclaimer:** This is an unofficial, community-maintained add-on made by a fan of the planefence project. It is not affiliated with or endorsed by kx1t / SDR-Enthusiasts. The add-on icon is AI-generated and not an official logo.
