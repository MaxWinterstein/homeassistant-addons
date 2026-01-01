# Home Assistant Add-on: CUPS Print Server

<a href='https://ko-fi.com/MaxWinterstein' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

A fully featured CUPS (Common UNIX Printing System) print server with working AirPrint support for Home Assistant.

---

## About

This add-on brings the power of CUPS to your Home Assistant installation, allowing you to:

- Share USB printers connected to your Home Assistant host with your entire network
- Enable AirPrint for iOS and macOS devices
- Manage printers through an intuitive web interface
- Print from any device on your network

Perfect for making your old USB printer wireless and accessible from all your devices!

---

## Features

- 🖨️ Full CUPS print server functionality
- 📱 AirPrint support via Avahi reflector mode
- 🌐 Web-based printer management interface
- 🔌 USB printer support
- 💾 Persistent configuration storage
- 🏠 Seamless Home Assistant integration

---

## Installation

1. Add this repository to your Home Assistant instance:
   [![Add repository on my Home Assistant][repository-badge]][repository-url]

2. Navigate to **Settings** → **Add-ons** → **Add-on Store**
3. Find "CUPS Print Server" and click on it
4. Click **INSTALL**

---

## Configuration

### Default Credentials

- **Username**: `print`
- **Password**: `print`

<!--
⚠️ **Security Note**: It's recommended to change the default password after first login. You can do this by modifying the Dockerfile and rebuilding the add-on.
-->

### Data Storage

Configuration data is persisted in the `/data/cups` folder, ensuring your printer settings survive add-on updates and restarts.

### USB Printer Setup

1. Connect your USB printer to your Home Assistant host
2. Start the add-on
3. Access the CUPS web interface (see Usage section below)
4. Add your printer through the Administration panel

---

## Usage

### Accessing CUPS Web Interface

After starting the add-on, access the CUPS management interface at:

```
http://homeassistant.local:631
```

Or using your Home Assistant IP address:

```
http://YOUR_HOME_ASSISTANT_IP:631
```

### Adding a Printer

1. Open the CUPS web interface
2. Click on **Administration** → **Add Printer**
3. Log in with credentials (default: print/print)
4. Select your USB printer from the list
5. Follow the setup wizard

### Printing from Devices

**iOS/macOS (AirPrint)**:

- Your printer should appear automatically in the print dialog
- No additional setup required!

**Windows**:

- Add printer using: `http://YOUR_HOME_ASSISTANT_IP:631/printers/PRINTER_NAME`

**Linux**:

- Your printer should be discoverable via CUPS/Avahi

---

## Network Configuration

This add-on uses **host networking** to enable proper printer discovery and AirPrint functionality. The following ports are used:

- **631/tcp**: CUPS web interface and printing
- **631/udp**: Printer discovery

---

## Troubleshooting

### Printer not showing up on iOS/macOS devices

- Ensure your device is on the same network as Home Assistant
- Check that the add-on is running
- Try restarting the add-on
- Verify Avahi/mDNS is not blocked by your network

### Can't access web interface

- Verify the add-on is running
- Check port 631 is not used by another service
- Try accessing via IP address instead of hostname

### USB printer not detected

- Ensure the printer is powered on
- Check USB cable connection
- Restart the add-on after connecting the printer
- Check the add-on logs for USB device detection

---

## Support

Found this add-on useful? Consider supporting my work:

<a href='https://ko-fi.com/MaxWinterstein' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

---

## Credits

**Based on the excellent work of [zajac-grzegorz](https://github.com/zajac-grzegorz/homeassistant-addon-cups-airprint) - thanks for letting me steal it ❤️**

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FMaxWinterstein%2Fhomeassistant-addons
