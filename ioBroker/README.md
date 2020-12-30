# Home Assistant Add-on: ioBroker

---
## 🚨 I do not guarantee that your ioBroker configuration will not get deleted! This is some early stage release! 🚨
---

This is a pretty basic implementation of ioBroker as Home Assistant Add-on. 
It is ment to provide some playground.

**This is no official add-on, neither from Home Assisant, nor from ioBroker.**

## Installation
After installation, and successfull startup, the ioBroker instance should be avaiable at port `8081`.  
If your HA instance is running with SSL support, the `OPEN WEB UI` button might not work correctly.  

## Technical notes
The `buanet` docker image contains some startup script that is pretty useful.

To ensure data stays persistent across restarts i simply softlink `/data` to `/opt/iobroker`.  
I removed some check that was not compatible with the symlink and not needed in our case.  
I added the unmodified version as reference.