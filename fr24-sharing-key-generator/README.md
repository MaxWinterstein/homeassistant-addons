# Home Assistant Add-on: FlightRadar24 Sharing Key Generator

<a href='https://ko-fi.com/MaxWinterstein' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armv7 Architecture][armv7-shield]

Quickly generate a Flightradar24 sharing key and view the setup process in your browser - all without leaving Home Assistant!

---

## About

This add-on wraps the Flightradar24 feeder and signup wizard to make it seamlessly usable as a Home Assistant add-on. Whether you want to contribute to the global flight tracking network or just need to generate a sharing key quickly, this add-on has you covered.

## Installation

1. Add this repository to your Home Assistant instance:
   [![Add repository on my Home Assistant][repository-badge]][repository-url]

2. Navigate to **Settings** → **Add-ons** → **Add-on Store**
3. Find "FlightRadar24 Sharing Key Generator" and click on it
4. Click **INSTALL**

---

## Configuration

### Required Settings

Before starting the add-on, configure these essential parameters in the add-on options:

- **email**: Your email address (will receive the sharing key as backup)
- **latitude**: Your receiver's latitude (e.g., `52.5200`)
- **longitude**: Your receiver's longitude (e.g., `13.4050`)
- **altitude**: Your receiver's altitude in meters above sea level

### Optional Settings

- **sharing_key**: If you already have a key, enter it here (leave empty to generate new)
- **mlat**: Enable Multilateration for improved aircraft tracking accuracy (default: `false`)
- **confirm_settings**: Auto-confirm settings during signup (default: `true`)
- **autoconfig**: Enable automatic configuration (default: `false`)
- **receiver_type**: Type of receiver hardware
  - `1`: DVB-T
  - `2`: rtl-sdr
  - `3`: Beast
  - `4`: AVR
  - `5`: Radarcape
  - `6`: Other
- **raw_feed**: Enable raw data feed (default: `false`)
- **base_feed**: Enable base station feed (default: `false`)

### Example Configuration

```yaml
email: pilot@example.com
sharing_key: ""
mlat: true
latitude: 52.5200
longitude: 13.4050
altitude: 34
confirm_settings: true
autoconfig: false
receiver_type: "2"
raw_feed: false
base_feed: false
```

---

## Usage

### Quick Start

1. Configure the add-on with your email and location (see Configuration above)
2. Start the add-on
3. Click **OPEN WEB UI** to view the live signup process
4. Watch the logs for your sharing key

### Retrieving Your Sharing Key

After the add-on completes the signup process, look for a log line similar to:

> _Your sharing key (**abc123def456**) has been configured and emailed to you for backup purposes._

The value in parentheses (e.g., `abc123def456`) is your Flightradar24 sharing key.

### Accessing the Web Interface

The add-on provides a built-in web interface accessible through:

- **Home Assistant Ingress**: Click "OPEN WEB UI" in the add-on page

## Troubleshooting

### No sharing key appears in logs

- Verify your email address is valid
- Check your location coordinates are correct
- Ensure the add-on has internet connectivity
- Review the full logs for any error messages

### Web UI not accessible

- Verify the add-on is running
- Review add-on logs for startup errors

### Email not received

- Check your spam/junk folder
- Verify the email address in configuration is correct
- Note: Some email providers may delay delivery
- The key is still displayed in the logs regardless

### Configuration validation errors

- Ensure latitude is between -90 and 90
- Ensure longitude is between -180 and 180
- Altitude must be a positive integer
- Email must be in valid format


## Support

Found this add-on useful? Consider supporting my work:

<a href='https://ko-fi.com/MaxWinterstein' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>


## Credits

This add-on uses the excellent [docker-fr24feed-piaware-dump1090](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090) Docker image by [Thom-x](https://github.com/Thom-x) as its base.

**Thank you, Thom-x, for your fantastic work for the community!**

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FMaxWinterstein%2Fhomeassistant-addons