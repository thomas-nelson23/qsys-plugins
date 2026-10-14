# Nanoleaf Open API plugin for Q-SYS

`Nanoleaf.qplug` controls one Nanoleaf controller per plugin instance over the local Nanoleaf Open API
(HTTP, port 16021). It covers Light Panels (Aurora), Canvas, Shapes, Elements and Lines.

## Install
1. Copy `Nanoleaf.qplug` to `Documents\QSC\Q-Sys Designer\Plugins`.
2. Restart Q-SYS Designer. The plugin appears under **Plugins > Lighting > Nanoleaf Open API**.
3. Drag it into the design. Use one instance per Nanoleaf controller.

## Set up and pair
1. Give the Nanoleaf controller a DHCP reservation so its IP never changes, and put it on a network the Core can reach.
2. On the **Setup** page, enter the IP address.
3. Hold the controller's power button for 5-7 seconds until the LEDs flash. Then press **Pair** within 30 seconds.
4. The token appears in **Auth Token** and the status turns OK.
5. **Save the token in the design.** Copy it into the Auth Token field in Designer (not while emulating or running) and save. Otherwise a re-deploy can wipe it.

**Unpair** deletes the token from the Nanoleaf. **Connect / Refresh** reconnects after you change the IP or token.

## Pages
| Page | What it does |
|---|---|
| **Control** | Power toggle and On/Off; brightness fader, +/- step, fade time; hue, saturation, R/G/B faders, hex entry and a live color swatch; color temperature fader with Candle/Warm/Neutral/Daylight/Cool presets; 8 quick-color buttons |
| **Effects** | Scene/effect dropdown loaded from the device; Now Playing; Prev/Next; a 12-button preset grid with paging that lights the active effect; Rhythm indicators and mic/AUX input select |
| **Panels** | Panel count, global orientation, Identify (flash); pick an individual panel and set its RGB color, or set all panels, with a transition time |
| **Setup** | IP, auth token, Pair/Unpair, last error, plus model, serial, firmware and manufacturer |

The header on every page shows the device name, the Q-SYS status (OK / Fault / Not Present / Initializing) and a cyan Online LED.

**Look:** the layout follows the Console style guide v1.1 (vaporwave palette): violet-grey panels, Nanoleaf green as the brand accent (effect pads, active buttons, faders), semantic cyan/amber/red for status LEDs and Identify/Unpair, and one hint line at the bottom of each page. Color swatches, the RGB/hue/kelvin faders and the quick-color buttons show their own colors.

**Properties:** Port (default 16021), Poll Interval (default 3 s), and Debug Print (None / Errors / All).

Every control has a pin, so UCI buttons, control scripts and snapshots can drive it.

## How it works
- **Polling:** it sends `GET /api/v1/<token>/` every poll interval. That one call returns state, effects, layout and rhythm.
- **Writes:** it sends `PUT /state` (`on`, `brightness` with `duration`/`increment`, `hue`, `sat`, `ct`) and `PUT /effects` (`select`, plus `write` with `animType: "static"` for per-panel color). It also uses `PUT /identify`, `PUT /panelLayout` (`globalOrientation`) and `PUT /rhythm` (`rhythmMode`).
- **Pairing:** `POST /api/v1/new` pairs and `DELETE /api/v1/<token>` unpairs.
- **One request at a time:** repeated fader moves are merged, so dragging a fader sends only the latest value. Poll feedback ignores a control for 2 s after you touch it, so faders don't jump back.
- **RGB:** the API has no RGB setter for the whole device, so R/G/B and hex are converted to hue/sat/brightness. That is the same method the open-source `nanoleafapi` library uses.

## Limitations / not tested on hardware
**This plugin has not been run against a real Nanoleaf or a real Q-SYS Core.** The logic was tested in a Lua 5.3 harness with mocked Q-SYS controls, `HttpClient`, `Timer` and `rapidjson`, against a simulated Nanoleaf. That covered pairing (403 and 200), power, brightness, fade and step, RGB/hex/quick colors, white presets, effect select/next/prev/paging, per-panel static writes, identify, orientation, rhythm, write coalescing, going offline and coming back, and unpair. The layout previews (`preview_*.png`) are a close rendering, not a Designer screenshot.

Check these on site:
- **Layout styling:** that Designer renders the layout the same way. The plugin uses flat buttons, rounded corners, `TextColor` for button and text colors (per the Q-SYS layout reference), and runtime `.Color` on the swatch LEDs.
- **Per-panel color:** that `animType: "static"` behaves on your model and firmware. Some newer firmware may want a different `animData` format for large panel IDs.
- **Unpair on older firmware:** unpair uses `HttpClient.Delete`. On Q-SYS firmware without it, unpair is skipped.
- **Empty palette:** the static write's empty `palette` uses `rapidjson.array` when the Core provides it. Otherwise the field is left out.

Not included:
- mDNS/SSDP auto-discovery (enter the IP by hand).
- The real-time event stream (`/events`, SSE), so touch gestures are not reported. Polling is used instead.
- Screen Mirror, Music Visualizer setup, schedules and creating new animated scenes, which live in the Nanoleaf app or cloud. The plugin plays any scene already saved on the device.
- The Rhythm input select applies only to the Aurora Rhythm module.

## Sources
- Nanoleaf Open API documentation (official, requires a free developer account): https://forum.nanoleaf.me/docs/openapi
- Q-SYS HttpClient reference (Download/Upload/Delete, EventHandler signature): https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/HttpClient.htm
- Q-SYS Lua extensions reference: https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/Q-SYS_Extensions_to_Lua.htm
- Cross-check of endpoints and JSON bodies: `nanoleafapi` Python library source, https://github.com/MylesMor/nanoleafapi

The official Nanoleaf and Q-SYS developer pages could not be fully loaded from the build environment. Endpoint bodies were confirmed against the `nanoleafapi` source. The Q-SYS plugin layout properties (`GroupBox`/`Label` graphics, `Style`, `OffColor`, `CornerRadius`) follow the Q-SYS plugin conventions, so check them in Designer.

## Changelog
- 1.0: first release.
- 1.1: restyled to the Console style guide (vaporwave palette); no control or pin changes.
