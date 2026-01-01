# Home Assistant Add-On: AWTRIX

<a href='https://ko-fi.com/MaxWinterstein' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

## Based on (aka. stolen from) https://github.com/lubeda/repository

Thanks for the work! I just made it work again for Raspberry Pi, and did some tweaking here and there.

---

Original README.md below

---

**This is a beta release of the addon, use at your own risk**

There is no arrangement with blueforcer, so i build this by try and error. It works on my HA and it should work on many other HA. But no guarantee. Be careful.

# Warning

!!backup all your configs (premiumkey). uninstall the old version!!

## Usage

Access the server via ingress, so no port config is necesarry

The config and the apps folder are accesible as /config/awtrix/apps and /config/awtrix/config. So no ftp is needed

| option  | default | usage                                                                                                                                          |
| ------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| version | `beta`  | select the awtrix host to run beta => https://blueforcer.de/awtrix/beta/awtrix.jar or stable => https://blueforcer.de/awtrix/stable/awtrix.jar |
| lang    | `en_EN` | the language used e.g. for the DayOfTheWeeK App set "de_DE" for german                                                                         |

To go from stable to beta and vice versa you have to rebuild the addon!

See [awtrix homepage](https://docs.blueforcer.de/#/v2/README) for more details
