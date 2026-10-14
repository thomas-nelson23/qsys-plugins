# qsys-plugins

A collection of Q-SYS Designer plugins for controlling third-party devices from a Q-SYS Core.
Each plugin lives in its own folder with the `.qplug` file, a README covering setup and limitations, and preview images of every page.

## Plugins

| Plugin | Version | Controls | Protocol | Download |
|---|---|---|---|---|
| [Nanoleaf Open API](nanoleaf/) | 1.0 | Nanoleaf Light Panels, Canvas, Shapes, Elements and Lines: power, brightness, color, white, effects, per-panel color | Local Nanoleaf Open API, HTTP port 16021 | [Nanoleaf.qplug](nanoleaf/Nanoleaf.qplug?raw=1) |
| [Philips Hue Bridge](philips-hue/) | 1.0 | Hue lights, rooms, zones and scenes: power, brightness, color, color temperature, scenes, effects | Local Hue API v2 (CLIP), HTTPS port 443 | [Hue.qplug](philips-hue/Hue.qplug?raw=1) |
| [FlexRadio FLEX-6600](flexradio/) | 1.0 | FLEX-6600 / FLEX-6000 transceivers: slices, frequency, band, mode, filter, AF gain, AGC, noise reduction, squelch, RIT, line out, guarded transmit (MOX, tune, ATU, power, TX audio source), meters | SmartSDR TCP/IP API, TCP port 4992, VITA-49 meters over UDP | [FlexRadio.qplug](flexradio/FlexRadio.qplug?raw=1) |
| [UniFi Network Monitor](unifi/) | 1.0 | UniFi consoles (UDM Pro and others): scrollable client list with IP, MAC and live bandwidth, internet and network health, WAN throughput, speed test, devices, firmware, ports and PoE, device restart, PoE power cycle, guest authorization | Local UniFi Network API (official Integration v1 plus legacy stats), HTTPS port 443, API key | [Unifi.qplug](unifi/Unifi.qplug?raw=1) |

## Install a plugin

1. Download the `.qplug` file from the plugin's folder (the Download link above, or open the file and click **Download raw file**).
2. Copy it to `Documents\QSC\Q-Sys Designer\Plugins` on the PC running Q-SYS Designer.
3. Restart Q-SYS Designer. The plugin appears in the Schematic Library under **Plugins**.
4. Drag it into your design and follow the setup steps in that plugin's README.

To get every plugin at once, use **Code > Download ZIP** on this page.

## Status

These plugins were tested in a Lua 5.3 harness against simulated devices, not yet on a real Q-SYS Core with real hardware. Each plugin's README lists what to check on site. Issues and pull requests with field results are welcome.

## Disclaimer

Not affiliated with or endorsed by QSC, Nanoleaf, Signify (Philips Hue), FlexRadio Systems or Ubiquiti. Product names are trademarks of their owners.
