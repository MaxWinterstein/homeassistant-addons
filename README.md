# Home Assistant Add-On repository (by Max Winterstein)

<a href='https://ko-fi.com/MaxWinterstein' target='_blank'><img height='35' style='border:0px;height:46px;' src='https://az743702.vo.msecnd.net/cdn/kofi3.png?v=0' border='0' alt='Buy Me a Coffee at ko-fi.com'></a>

_Everything here is ment to be **experimental**. Happy to see feedback!_

## Home Assistant Addon repository containing

### <img src="angry-ip-scanner/icon.png" width="40px"> Angry IP Scanner

Wraps the well known [Angry IP Scanner](https://angryip.org/) to make it usable as Add-on.

### <img src="adsb-multi-portal-feeder/icon.png" width="40px"> ADB-S Multi Portal Feeder

Observe flight traffic using some cheap ADB-S USB-Stick and feed towards FlightRadar24 and FlightAware.

Based on the incredible [docker-fr24feed-piaware-dump1090](https://github.com/Thom-x/docker-fr24feed-piaware-dump1090) docker image by [Thom-x](https://github.com/Thom-x).

### <img src="eufy-ha-mqtt-bridge/icon.png" width="40px"> Eufy Home Assistant MQTT Bridge ([matijse/eufy-ha-mqtt-bridge](https://github.com/matijse/eufy-ha-mqtt-bridge))

Forwards Eufy Security push notifications to Home Assistant via MQTT.

### <img src="toogoodtogo-ha-mqtt-bridge/icon.png" width="40px"> TooGoodToGo Home Assistant MQTT Bridge ([maxwinterstein/toogoodtogo-ha-mqtt-bridge](https://github.com/maxwinterstein/toogoodtogo-ha-mqtt-bridge))

Integrate your TooGoodToGo favourites to Home Assistant via MQTT.

### <img src="ioBroker/icon.png" width="40px"> ioBroker ([iobroker.net](http://iobroker.net))

Run ioBroker as Add-on.

### <img src="octoprint-proxy/icon.png" width="40px"> OctoPrint Reverse Proxy ([octoprint.org](http://octoprint.org))

Small proxy to add OctoPrint to the Home Assistant.

## Installation

Go to the _Supervisor_ Panel, select _Add-on Store_, click the three little dots on the upper right and select _Repositories_. Now fill the _Add repository_ testbox with `https://github.com/MaxWinterstein/homeassistant-addons/` and click _Add_.

![installation](https://raw.githubusercontent.com/MaxWinterstein/homeassistant-addons/main/add_repository.png)

## Deprecated add-ons

### <img src="portainer/icon.png" width="40px"> Portainer v1.5.2 ([hassio-addons/addon-portainer](https://github.com/hassio-addons/addon-portainer))

#### I would no longer suggest to use this. There are way better alternatives out there, e.g. https://github.com/alexbelgium/hassio-addons/tree/master/portainer

This is a complete copy of https://github.com/hassio-addons/addon-portainer/tree/v1.5.2

As the current version (`2.0.0` at this time) of this addon has problems with starting containers this clone simply provides easy access to v1.5.2.

See https://community.home-assistant.io/t/portainer-v2-6-2-unable-to-start-containers/332356 or https://github.com/hassio-addons/addon-portainer/issues/127 for more.
