# Home Assistant Add-on: CUPS Printer server

<a href='https://ko-fi.com/MaxWinterstein' target='_blank'><img height='35' style='border:0px;height:46px;' src='https://az743702.vo.msecnd.net/cdn/kofi3.png?v=0' border='0' alt='Buy Me a Coffee at ko-fi.com'></a>

## Credits

This Add-On is based on the work of https://github.com/Luk164/addon-repository - and just slighty adjusted to make it work. Thanks <3

## Known Issues 🚨

- mDNS is not working, therefore e.g. printeres are not announced via Avahi / Bonjour - see [#128](https://github.com/MaxWinterstein/homeassistant-addons/issues/128)
- Ingress is not working, so I disabled it for now. Please access the Webinterface via port 631, e.g. https://192.168.1.2:631 - see [#129](https://github.com/MaxWinterstein/homeassistant-addons/issues/129)
