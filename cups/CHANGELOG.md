# Changelog

## 2.0.3 -- 19.12.2022

- Also build for armv7

## 2.0.2 -- 18.12.2022

- Fix permisson error

## 2.0.1 -- 18.12.2022

- Fix permisson error

## 2.0.0 -- 18.12.2022

- Changed `init` to `false` to make it at least starting.

---

Original Changelog:

## 1.0.0-alpha.25

- Used documented ingress path header for rewrites, removed JS

## 1.0.0-alpha.24

- Modified Nginx configuration to get the authentication token from JS

## 1.0.0-alpha.23

- Fixed Avahi config to use D-Bus again
- Made Nginx authenticate supervisor requests
- Used container fqdn instead of Home Assistant hostname for certificate filenames

## 1.0.0-alpha.22

- Removed debug log level in CUPS
- Made Avahi wait to be configured before starting

## 1.0.0-alpha.21

- Debug: increased CUPS log level

## 1.0.0-alpha.20

- Removed debugging print statements from run.sh
- Added export statement to http.js
- Mapped Home Assistant hostname into avahi-daemon.conf
- Removed DNSSDHostName key from cupsd.conf (introduced in later version)

## 1.0.0-alpha.19

- Replaced const with var in http.js
- Automatically generated /data/cups on first run

## 1.0.0-alpha.18

- Fixed nginx.conf typo
- Debug: print debugging in run.sh

## 1.0.0-alpha.17

- Persisted all CUPS configuration
- Refreshed all certificates on startup
- Added a CSP on ingress to disable the CUPS frame-blocker
- Rewrote absolute page URLs on ingress to point to the proxied URL
- Redirected printer advertisements to the domain name of the Home Assistant installation
- Disabled mDNS address responses for the container
- Added more default drivers

## 1.0.0-alpha.16

- Flipped order of arguments in ln command

## 1.0.0-alpha.15

- Fixed bug in run.sh caused by a variable in an if statement

## 1.0.0-alpha.14

- Added D-Bus back
- Fixed SSL support for CUPS - new config options
- Added startup dependencies for CUPS and Avahi

## 1.0.0-alpha.13

- Added a delay so CUPS starts after Avahi is up
- Debug: removed IP filter on ingress controller

## 1.0.0-alpha.12

- Attempted to remove D-Bus

## 1.0.0-alpha.11

- Turned off D-Bus support in Avahi
- Created a folder for D-Bus to store its socket

## 1.0.0-alpha.10

- Added a D-Bus daemon into the container directly

## 1.0.0-alpha.9

- Mapped the host D-Bus service into the container
- Added an events section to nginx.conf

## 1.0.0-alpha.8

- Fixed shebang to point to /bin/sh instead of /usr/bin/sh

## 1.0.0-alpha.7

- Normalized line endings to LF

## 1.0.0-alpha.6

- Replaced execlineb with sh
- Removed debug info for ingress
- Added nginx to proxy requests for ingress

## 1.0.0-alpha.5

- Replaced bashio with execlineb in service script
- Added debug info for ingress

## 1.0.0-alpha.4

- Moved this changelog into the correct directory
- Added exec command to run script
- Fixed external hostname mapping

## 1.0.0-alpha.3

- Added this changelog
- Added all configured hostnames to allowlist
- Added avahi-daemon service

## 1.0.0-alpha.2

- Updated link to repository
- Fixed unescaped newlines causing container start to fail in run.sh

## 1.0.0-alpha.1

- Initial release
