# Philips Hue Bridge plugin for Q-SYS

`Hue.qplug` controls the lights on one Philips Hue Bridge per plugin instance. It uses the Bridge's local
Hue API v2, which Philips calls the CLIP API (HTTPS, port 443). It covers lights, rooms, zones, scenes, brightness, color,
color temperature and the built-in light effects, which is most of what the Hue app does day to day.

## Install
1. Copy `Hue.qplug` to `Documents\QSC\Q-Sys Designer\Plugins`.
2. Restart Q-SYS Designer. The plugin appears under **Plugins > Lighting > Philips Hue Bridge**.
3. Drag it into the design. Use one instance per Hue Bridge.

## Set up and pair
1. Give the Hue Bridge a DHCP reservation so its IP address never changes. Put it on a network the Core can reach on TCP 443.
2. On the **Setup** page, enter the Bridge IP.
3. Press **Pair**, then press the round link button on top of the bridge within 30 seconds. The plugin retries every 2 s while it waits.
4. The app key appears in **App Key** and the status turns OK.
5. **Save the app key in the design.** Copy it into the App Key field in Designer (not while emulating or running) and save. Otherwise a re-deploy can wipe it.

**Forget Key** clears the key in the plugin. API v2 has no local call to delete a key from the bridge, so remove it in the Hue app (Settings > Apps) if it should be revoked there too. **Connect / Refresh** reconnects and reloads rooms, zones and scenes.

## Pages
| Page | What it does |
|---|---|
| **Control** | Target picker (All Lights, any room, zone or single light) and Identify (breathe). Power toggle and On/Off. Brightness fader with +/- step and fade time. Hue, saturation, R/G/B faders, hex entry, a live swatch and the color mode. A Kelvin fader with the Hue app's white recipes (Relax, Read, Neutral, Concentrate, Energize). 8 quick colors. |
| **Rooms** | All On / All Off with a count of lights on. 8 room and zone tiles with paging, each with power, brightness, an "x of y on" count and **Control >** to make it the Control page target. |
| **Lights** | Filter by room or zone. 8 light tiles with paging, each with a color swatch, power, brightness, state text (level, Kelvin or effect) and **Control >**. |
| **Scenes** | Pick a room or zone, then a 12-button scene grid with paging that lights the active scene. It has a transition time, a **Dynamic** toggle (plays the scene's palette) and Room Off. **Light Effects** sends candle, fire, sparkle, prism and the rest to the Control target. |
| **Setup** | Bridge IP, app key, Pair / Forget Key, last error, and the bridge ID, model, software version and counts. |

The header on every page shows the bridge name, the Q-SYS status (OK / Fault / Not Present / Initializing) and an Online LED.

**Properties:** Poll Interval (default 2 s), Group Command Interval (default 1000 ms) and Debug Print (None / Errors / All).

Every control has a pin, so UCI buttons, control scripts and snapshots can drive it. `SceneSelect` is a pin-only text input that recalls a scene by name in the room picked on the Scenes page.

## How it works
- **Requests:** every call goes to `https://<bridge>/clip/v2/resource/...` with the `hue-application-key` header.
- **Pairing:** it sends `POST /api` with `{"devicetype": "qsys_hue#core", "generateclientkey": true}`. The bridge answers error 101 ("link button not pressed") until the button is pressed, then returns `success.username`, which is the app key.
- **Reading:** on connect, and every 30 polls, it reads `bridge`, `device`, `room`, `zone`, `bridge_home`, `light`, `grouped_light` and `scene`. Each normal poll reads only `light`, `grouped_light` and `scene`.
- **Rooms and zones:** a room's lights come from its child devices' `light` services. A zone lists its lights directly. Commands to a room, zone or All Lights go to that group's `grouped_light` (All Lights uses the `bridge_home` grouped light).
- **Writes:** `PUT light/<id>` or `PUT grouped_light/<id>` with `on`, `dimming.brightness`, `dimming_delta` (+/- buttons), `color.xy`, `color_temperature.mirek`, `alert` (breathe) and `dynamics.duration` (fade). Effects use `PUT light/<id>` with `effects.effect`. Scenes use `PUT scene/<id>` with `recall.action` set to `active` or `dynamic_palette`, plus `recall.duration`.
- **Color:** RGB, hex and hue/sat are converted to CIE xy with Philips' published method: gamma correction, then the Wide RGB D65 matrix. For a single-light target the point is clipped to that lamp's gamut, which the bridge reports. Feedback converts xy back to RGB the same way. Kelvin is sent as mirek (1,000,000 / K), clamped to the lamp's `mirek_schema`.
- **Brightness 0** turns the target off. Changing brightness, color or white turns the target on, as in the Hue app.
- **Rate limits:** one request is in flight at a time. Repeated fader moves to the same resource are merged, so a drag sends only the latest value. Hue's guidance is about 10 commands/s to lights and 1/s to groups, so light writes are spaced 100 ms apart and group or scene writes use the Group Command Interval. A 429 reply is retried once after 1 s. Poll feedback ignores a control for 2 s after you touch it, so faders don't jump back.
- **Group color feedback:** `grouped_light` reports only on and brightness. For a room or zone target, the color, white and effect feedback comes from the first lit light in it.

## Limitations / not tested on hardware
**This plugin has not been run against a real Hue Bridge or a real Q-SYS Core.** The logic was tested in a Lua 5.3 harness with mocked Q-SYS controls, `HttpClient`, `Timer` and `rapidjson`, against a simulated CLIP v2 bridge (10 lights, 3 rooms, 1 zone, 14 scenes). The tests covered:
- pairing (error 101, success and the 30 s timeout)
- room, zone, light and All Lights targets
- power, brightness, the zero-turns-off rule and `dimming_delta`
- fader merging and the fade duration
- RGB/hex/quick colors with gamut clipping
- white presets and the Kelvin to mirek conversion
- identify, effects (skipping lamps that don't support them) and scene recall (static and dynamic, by button and by name)
- room and light tiles, filters and paging
- going offline and coming back, an invalid key (403) and Forget Key

The layout previews (`preview_*.png`) are a close rendering, not a Designer screenshot.

Check these on site:
- **HTTPS certificate:** API v2 is HTTPS only. The Hue Bridge uses a certificate signed by Signify's own root CA, not a public CA. Q-SYS's HttpClient documentation covers `https://` URLs and TLS 1.0-1.3 but says nothing about certificate checks. If the Core rejects the bridge certificate, Last Error shows the HttpClient error on every poll. This is the first thing to confirm.
- **Layout styling:** check that Designer renders the layout the same way. The plugin uses flat buttons, rounded corners, and runtime `.Color` on the swatch LEDs.
- **Group speed:** a room fader updates at most once per Group Command Interval. Lowering it below 1000 ms is faster but goes past Hue's guidance.
- **Effects:** only lamps that list the effect in `effects.status_values` get it. Older bulbs have no effects.

Not included:
- Bridge discovery (mDNS or discovery.meethue.com). Enter the IP by hand.
- The event stream (`/eventstream/clip/v2`, server-sent events), because HttpClient can't hold a streaming connection. Polling is used instead.
- Entertainment areas and sync, gradient per-segment color, timed effects (sunrise), smart scenes, sensors, switches and automations.
- Creating or editing rooms, zones and scenes. Do that in the Hue app; the plugin picks them up on the next full read or Refresh.

## Sources
- Philips Hue developer portal: Hue API v2 announcement. It confirms that v2 is HTTPS only, explains how v2 relates to v1, and recommends not using REST for fast continuous updates. https://developers.meethue.com/?p=3403
- Philips Hue developer portal, "Get started": the `POST /api` pairing flow with the link button, and the `https://<bridge>/debug/clip.html` test tool. https://developers.meethue.com/develop/get-started-2/
- Philips Hue developer portal, rate guidance: about 10 commands/s to lights and 1/s to groups. https://developers.meethue.com/?p=497
- Philips Hue "RGB to xy Color conversion" application design note, which gives the gamma, the Wide RGB D65 matrix, gamut clipping and the reverse conversion: https://github.com/johnciech/PhilipsHueSDK/blob/master/ApplicationDesignNotes/RGB%20to%20xy%20Color%20conversion.md
- Cross-check of CLIP v2 endpoints, the `hue-application-key` header and JSON bodies against the OpenHue OpenAPI description of the Hue API v2 (a community project): https://github.com/openhue/openhue-api
- Q-SYS HttpClient reference (Download/Upload, Headers, HTTPS, EventHandler signature): https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/HttpClient.htm

Most of the official Hue API v2 reference pages on developers.meethue.com require a developer login, and the build environment could not open them. The v2 resource paths and body fields were taken from the OpenHue description and checked against the public Philips pages above. Check the `GroupBox`/`Label` graphics, `Style`, `OffColor` and `CornerRadius` layout properties in Designer, since they follow Q-SYS plugin conventions rather than a tested design.
