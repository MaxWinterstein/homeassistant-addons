# Home Assistant Add-on: FlightRadar24 Sharing Key Generator

<a href='https://ko-fi.com/MaxWinterstein' target='_blank'>
  <img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' />
</a>

Quickly generate a Flightradar24 Sharing Key and view the setup log in your browser.

Wraps the Flightradar24 feeder and signup wizard to make it usable as a Home Assistant Add-on.

---

## Features

- Automated signup for a Flightradar24 sharing key
- Live, auto-refreshing, styled log page
- All configuration via add-on options
- Output also visible via `docker logs` or Home Assistant log viewer

---

## Usage

1. Install the add-on from [this repository](https://github.com/MaxWinterstein/homeassistant-addons/).
2. You can start the add-on right away with the default configuration, but for best results, it’s recommended to adjust the configuration (such as email, location, etc.) in the add-on options.
3. Start the add-on.
4. Visit the add-on web UI to see the live log and retrieve your sharing key.

**How to find your sharing key:**  
After running the add-on, look for a log line like this in the output:

> _Your sharing key (**abc123def456**) has been configured and emailed to you for backup purposes._

The value in parentheses is your Flightradar24 sharing key.

---

## Credits

This add-on uses the excellent [docker-fr24feed-piaware-dump1090](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090) Docker image by [Thom-x](https://github.com/Thom-x) as its base.  
**Thank you, Thom-x, for your fantastic work for the community!**
