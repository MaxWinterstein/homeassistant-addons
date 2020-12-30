# Home Assistant Add-on: ioBroker

---
## 🚨 I do not guarantee that your ioBroker configuration will not get deleted! This is some experimental release! 🚨
---

This is a pretty basic implementation of ioBroker as Home Assistant Add-on. 
It is meant to provide some playground.

**This is no official add-on, neither from Home Assisant, nor from ioBroker.**

## Installation
After installation, and successful startup, the ioBroker instance should be available at port `8081`.  
If your HA instance is running with SSL support, the `OPEN WEB UI` button might not work correctly.  

**Note:** As this image is not based on the official home assistant add-on images the Supervisor has some delay on the add-on state (i guess this is the reason).  
It might be up and running while the `Info` tab is not aware of this right now. Page reload might help.

## Technical notes
The `buanet` docker image contains some pretty useful startup script.

To ensure data stays persistent across restarts I simply softlink `/data` to `/opt/iobroker`.  
I removed some check that was not compatible with the symlink and not needed in our case.  
I added the unmodified version as a reference.