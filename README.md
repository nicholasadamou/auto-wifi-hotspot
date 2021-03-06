# Auto-WiFi-Hotspot

![license](https://img.shields.io/apm/l/vim-mode.svg)
[![Say Thanks](https://img.shields.io/badge/say-thanks-ff69b4.svg)](https://saythanks.io/to/NicholasAdamou)

A script to allow the Raspberry Pi to connect to a known WiFi network or automatically generate an Access Point if no network is found. You can then use `SSH` or `VNC` on the move and switch between the hotspot and network without a reboot.

What it Sets Up
------------
* HostAPD (Access Point) on `wlan0`
* WiFi Connection on `wlan1` or `eth0`

Requirements
------------

* Two WiFi Cards (e.g. On-board chip + [TL-WN725N](https://www.amazon.com/gp/product/B008IFXQFU/ref=oh_aui_detailpage_o03_s00?ie=UTF8&psc=1))
* Micro-USB to USB 2.0/3.0 converter (e.g. [USB to Micro-USB Charge & Sync Cable](https://www.amazon.com/gp/product/B00SVVY844/ref=oh_aui_detailpage_o05_s00?ie=UTF8&psc=1))
* Portable Battery Bank (e.g. [Anker PowerCore 5000](https://www.amazon.com/gp/product/B01CU1EC6Y/ref=oh_aui_detailpage_o02_s00?ie=UTF8&psc=1))

Older versions may work but aren't regularly tested. Bug reports for older
versions are welcome.

*Note: some WiFi dongles don't work in `adhoc mode` or don't work with with the `nl80211 driver` used in this guide for the `Raspberry Pi 3`, so consult your WiFi dongle manual before starting.*

Install
-------

Download, review, then execute the script:

```
git clone git://github.com/NicholasAdamou/Raspberry-Pi-Auto-WiFi-Hotspot-Switch-Internet.git && cd Raspberry-Pi-Auto-WiFi-Hotspot-Switch-Internet && ./src/setup.sh
```

Follow the on-screen directions.

It should take less than 5 minutes to install.


More Information
-------

* [Raspberry Pi - Auto WiFi Hotspot Switch Internet](http://www.raspberryconnect.com/network/item/330-raspberry-pi-auto-wifi-hotspot-switch-internet)

License
-------

Auto-WiFi-Hotspot is © Nicholas Adamou.

It is free software, and may be redistributed under the terms specified in the [LICENSE] file.

[LICENSE]: LICENSE
