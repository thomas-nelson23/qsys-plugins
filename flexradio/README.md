# FlexRadio FLEX-6600 plugin for Q-SYS

`FlexRadio.qplug` controls a FlexRadio FLEX-6600 or 6600M (and other FLEX-6000 series radios) over the SmartSDR TCP/IP API.
It shows and controls the radio's slice receivers (frequency, band, mode, filter, AF gain, AGC, NB / NR / ANF / WNB, squelch,
RIT, RX antenna), the radio's own line out and headphone levels, and a guarded transmit page (MOX, TUNE, PTT, ATU, RF and
tune power, TX antenna, TX audio source and mic level) with forward power, SWR, mic, PA temperature and supply meters, plus the interlock state.

It does not carry audio: a Q-SYS plugin script has no audio pins, so the radio's network audio (DAX) cannot pass through
it. Use analog audio both ways, as below, and the plugin for control and PTT.

## Audio wiring (analog, both ways)
- **Receive:** the radio's line out (or headphone out) into a Q-SYS input. **Line Out** and **Phones** gain and mute are on the
  DSP page; slice AF gain is on the Receive page.
- **Transmit:** a Q-SYS output into the radio input you will transmit from (line, ACC or mic). Pick that input with
  **TX Audio** on the Transmit page and set **Mic Level** while watching the MIC meter. Check jack levels and pinout in the
  FLEX-6600 manual before wiring, and start with the Q-SYS output and Mic Level low.
- Key with **PTT (hold)** or the `PTT` pin from a UCI or a Q-SYS control script; all the transmit guards below still apply.
  Choosing the source and level never keys the radio.

## Install
1. Copy `FlexRadio.qplug` to `Documents\QSC\Q-Sys Designer\Plugins`.
2. Restart Q-SYS Designer. The plugin appears under **Plugins > Radio > FlexRadio FLEX-6600 (SmartSDR)**.
3. Drag it into the design. Use one instance per radio.

## Set up
1. Give the radio a fixed IP (DHCP reservation or static) so the Core always finds it.
2. The Core must reach the radio on **TCP 4992**, and the radio must reach the Core on the **Meter UDP Port**
   (default 4993, a Property). Keep them on the same subnet, or open both through any firewall between them.
   If two plugin instances run on one Core, give each a different Meter UDP Port.
3. On the **Setup** page, type the radio's IP. The plugin connects, reads the radio, and reconnects on its own if the link drops.
4. Pick the **Client Mode** in Properties:
   - **Follow SmartSDR (non-GUI)** (default). The plugin joins as a non-GUI client, like SmartSDR CAT or DAX. It shows and
     controls the slices that SmartSDR, Maestro or the 6600M front panel already has open. If no GUI client is connected, the
     radio has no slices and the Receive page is empty.
   - **Standalone (GUI client)**. The plugin registers as a GUI client (it takes one of the radio's two Multi-Flex GUI
     places) and can add and remove its own slices with **Add Slice / Remove Slice** on the Setup page. Not tested; see below.
5. Leave **Transmit** set to **Disabled** unless this Q-SYS system really should key the radio. See the next section first.

## Transmit safety
Keying a transmitter into the wrong antenna, an open coax or a dummy load that is not connected can damage the radio and
equipment, and RF exposure is a hazard to people. The plugin is built so that it never transmits by surprise:

- **Transmit is Disabled in Properties by default.** While disabled, MOX, TUNE, PTT and ATU TUNE are greyed out and the
  plugin never sends `xmit 1`, `transmit tune on` or `atu start`. Power, TX slice and TX antenna can still be set.
- **ARM is required.** With Transmit enabled, MOX, TUNE, PTT and ATU TUNE only work within the **Arm Timeout** (default 30 s)
  after ARM is pressed. ARM stays on while keyed and starts counting again after unkey. Turning ARM off while keyed unkeys.
- **The radio's interlock must say it can transmit.** The plugin refuses to key unless the radio reports `tx_allowed=1` and
  state `READY`. The interlock state, PTT source and any reason (for example `PA_RANGE`, `ACC_TXREQ`, `AMP:<name>`) are shown.
- **Time limits.** MOX and PTT unkey after **Max MOX Time** (default 120 s), TUNE after **Max Tune Time** (default 15 s).
  The radio's own transmit timeout (`interlock timeout`) still applies and is not changed by the plugin.
- **SWR trip.** While on air above 1 W, an SWR at or above **SWR Trip** (default 3.0, or Off) for 0.5 s unkeys and disarms.
  This is not used during an ATU tune cycle, where a high SWR is expected.
- **STOP** sends `xmit 0` and `transmit tune off` and disarms. It always works, even with Transmit disabled, and it also
  unkeys a transmission started by another client.
- If the link to the radio drops while the plugin had the radio keyed, the plugin sends `xmit 0` as soon as it reconnects.
  It does not know about a key-down from before a Core restart, so a Core reboot during MOX relies on the radio's own timeout.

Use the radio's own safety features as well (interlock timeout, TX inhibit, amplifier interlocks). Only enable Transmit when a
suitable antenna or load is connected, and when the people using the touch screen are licensed to operate the station.

## Pages
| Page | What it shows |
|---|---|
| **Receive** | Four slice tiles (letter, frequency, mode, the GUI station that owns it, a red TX dot). Tap a tile to control that slice; **Follow Active** tracks the slice that SmartSDR has active. A large frequency field (type `14.2055` in MHz, `14205.5` in kHz, or `14.205.500`), step down / up and x10 buttons with a step list (10 Hz to 100 kHz, snapping to the step). S-meter in S units and dBm. Band buttons 160 to 6 m and WWV, mode buttons (modes the slice does not offer are dimmed), six filter presets per mode with the passband readout, AF gain, mute and RX antenna. |
| **DSP** | AGC Off / Slow / Med / Fast and threshold. Squelch on and level. NB, NR, ANF and WNB on/off with levels. RIT on, offset (±2 kHz) and clear. The radio's line out and headphone gain and mute. |
| **Transmit** | ARM, the arm countdown and messages, STOP. MOX, TUNE, PTT (hold), ATU TUNE / BYPASS and the ATU result. RF power, tune power (percent of full output, 100 W on the 6600; tune power also drives the ATU tune), mic level and TX audio source (the inputs the radio lists, except its test-signal generators). On-air and TX-allowed LEDs, interlock state with PTT source, reason, TX slice with **Set TX** (makes the selected slice the transmitter; does not key), TX antenna. Meters: forward power (W), SWR, mic peak, reflected power, PA temperature and supply voltage. |
| **Setup** | Radio IP and Connect, client mode, meter stream status, last error. Model, serial, firmware, callsign, nickname, GPS and the connected GUI clients. Add / Remove Slice (Standalone mode) and the last radio message. |

The header on every page shows the radio nickname and model, the Q-SYS status (OK / Fault / Not Present / Initializing) and an
Online LED.

**Properties:** Client Mode, Meter UDP Port (4993), Transmit (Disabled / Enabled), Arm Timeout (30 s), Max MOX Time (120 s),
Max Tune Time (15 s), SWR Trip (3.0), Debug Print (None / Errors / All). The four transmit limits only show when Transmit is
Enabled.

**Pins:** most controls have pins. Useful ones for UCIs and scripts: `FrequencyMHz`, `SignalDbm`, `FwdWatts`, `Swr`,
`Transmitting`, `TxAllowed`, `Mute`, `AFGain`, `Band 1-12`, `Mode 1-10`, `PTT` (momentary input, still needs ARM),
`TxArm`, `TxStop`.

## How it works
**Control (TCP 4992).** On connect the radio sends `V<version>` and `H<handle>`. The plugin then sends
`client udpport <port>`, `keepalive enable`, `info`, `version`, `sub radio all`, `sub slice all`, `sub tx all`, `sub atu all`,
`sub client all`, `sub meter all` and `meter list` (Standalone mode first sends `client gui [client_id]` and
`client station Q-SYS`, and keeps the returned client ID in a hidden control so the radio sees the same client next time).
Commands are `C<seq>|<command>`; every one gets one `R<seq>|<hex>|<message>` (0 = OK). The radio pushes `S<handle>|...`
status lines for every change, from any client, so the panel follows SmartSDR and the front panel live. `ping` is sent every
second (the keepalive requires one at least every 15 s); if nothing is heard for 6 s the plugin reconnects.

Commands used: `slice t <n> <MHz> autopan=1` (tune), `slice s <n> mode= audio_level= audio_mute= rxant= agc_mode=
agc_threshold= nb= nb_level= nr= nr_level= anf= anf_level= wnb= wnb_level= squelch= squelch_level= rit_on= rit_freq= tx=1
txant=`, `filt <n> <low Hz> <high Hz>`, `display pan s <pan> band=<n>` (band buttons, which recalls SmartSDR's band memory;
if the slice has no panadapter or the radio refuses, the plugin tunes the slice to the last frequency it used on that band or a
default), `mixer lineout gain|mute`, `mixer headphone gain|mute`, `transmit set rfpower= tunepower= miclevel=`, `mic list`, `mic input <mic|line|acc|pc...>`, `xmit 1|0`,
`transmit tune on|off`, `atu start`, `atu bypass`, `slice create`, `slice r`.

Slider moves are coalesced: only the newest value per control is sent, ten times a second, and the slider ignores radio
feedback for 2 s after you touch it so it does not jump back.

**Meters (UDP, VITA-49).** The radio sends meter values to the Core in VITA-49 extension packets (class code `0x8002`), each
holding pairs of a 16-bit meter ID and a 16-bit value. Meter names, sources and units come from `meter list` and the `meter`
status lines. Scaling: dBm, dBFS and SWR / 128, volts / 256, degrees C / 64. Forward and reflected power are dBm and shown in
watts. The S-meter is the selected slice's `LEVEL` meter, with S9 = -73 dBm and 6 dB per S unit (the HF convention, also used
on 6 m here).

**Filter presets** (Hz): SSB widths 1.8k to 3.3k with the low edge at 100 Hz (USB `100..100+w`, LSB `-(100+w)..-100`), digital
widths 1k to 4k from 0 Hz, CW 50 to 1000 Hz and AM / SAM 5.6k to 16k centred on the carrier. FM, NFM, DFM and RTTY keep the
radio's filter and the presets are off.

**Band defaults** (used only when the panadapter band command is not available): 160 m 1.900 LSB, 80 m 3.800 LSB, 60 m 5.3305
USB, 40 m 7.200 LSB, 30 m 10.120 DIGU, 20 m 14.200 USB, 17 m 18.130 USB, 15 m 21.300 USB, 12 m 24.950 USB, 10 m 28.400 USB,
6 m 50.125 USB, WWV 10.000 AM. Band edges for the band highlight are US / Region 2.

## Limitations / not tested on hardware
**This plugin has not been run against a real FlexRadio or a real Q-SYS Core.** The logic was tested in a Lua 5.3 harness with
mocked Q-SYS controls, `TcpSocket`, `UdpSocket` and `Timer`, against a simulated FLEX-6600 that answers the commands above,
pushes status lines and sends VITA-49 meter packets. 148 checks passed, covering: handshake and subscriptions, rendering of
slices / DSP / outputs / interlock, frequency entry in MHz, kHz and Hz, step tuning and coalescing, band via panadapter and the
fallback with band memory, mode and filter presets, feedback hold, follow-active and manual slice selection, meter parsing
and scaling, meter add / remove, every transmit guard (disabled, unarmed, arm timeout, NOT_READY, MOX and tune time limits,
SWR trip, PTT, ATU, disarm while keyed, STOP, unkey after reconnect), TX audio source and mic level (coalescing, feedback, and that neither keys the radio), link loss, silence detection and reconnect, and
Standalone mode (client gui, client ID reuse, add / remove slice). The layout previews (`preview_*.png`) are a close rendering
of the layout with that test data, not a Designer screenshot.

Check these on site, ideally into a dummy load first:
- **Meter scaling of SWR.** The wiki only gives the scaling for dB units and for meters a client creates. SWR / 128 and
  volts / 256 come from xLib6000, an open-source port of FlexLib. Compare the plugin's SWR and supply voltage with SmartSDR.
- **Status field names.** The wiki's status page is old and only lists a few slice fields. `audio_level`, `audio_mute`,
  `agc_mode`, `rit_on`, `rit_freq`, `ant_list`, `tx_ant_list`, `mode_list`, `index_letter`, `tune` and the radio
  `lineout_*` / `headphone_*` fields come from xLib6000. Filter edges are read as Hz (the old wiki example shows MHz).
- **CW filter placement.** CW presets are centred on 0 Hz. If SmartSDR shows them offset by the CW pitch on your firmware,
  adjust `filterEdges` in the plugin.
- **Band numbers.** `display pan s <pan> band=<n>` is documented, but the exact band names SmartSDR uses (for example `60`, `6`,
  WWV) are not. If a band button tunes to the default frequency instead of the band memory, the radio refused the band name.
- **UDP meter stream.** The Core's firewall / network must let the radio's UDP packets reach the Meter UDP Port. The Setup
  page shows "No meter packets" if none arrive. Q-SYS allows one listener per UDP port per Core.
- **Non-GUI control of SmartSDR's slices.** Non-GUI clients (SmartSDR CAT, DAX) control GUI-owned slices on v3+ firmware, so
  this should work, but confirm tuning and mode changes from Q-SYS show up in SmartSDR.
- **Standalone (GUI client) mode** is the least certain part: a headless `slice create` without a panadapter may be refused on
  some firmware. Use Follow mode with SmartSDR or a 6600M front panel if it is.
- **TX audio inputs.** The wiki lists `mic, val, line, gen, acc, pc, noise` for `mic input`; the plugin shows whatever
  `mic list` returns (minus `GEN` and `NOISE`). The `mic_selection` and `mic_level` status names come from xLib6000.
- **Firmware.** Written for SmartSDR v3 / v4 firmware (Multi-Flex). v1 / v2 firmware used different audio commands.
- **Layout styling.** Check that Designer renders the layout as in the previews (flat buttons, rounded corners, meters, fonts).

Not included: audio streaming (DAX / remote audio), panadapter and waterfall, discovery (the IP is typed in), CW keyer and CWX
memories, DVK, memories, TX profiles, mic bias / boost and EQ, transverters, amplifier and tuner accessories beyond the internal ATU.

## Sources
- FlexRadio SmartSDR API documentation (official), GitHub wiki of `flexradio/smartsdr-api-docs`, revision of 2026-10-06:
  https://github.com/flexradio/smartsdr-api-docs/wiki. Pages used: SmartSDR-TCPIP-API (connection, command, response,
  status and message formats), TCPIP-slice, TCPIP-filt, TCPIP-xmit, TCPIP-transmit, TCPIP-atu, TCPIP-mixer, TCPIP-sub,
  TCPIP-meter and Metering-Protocol (meter list format, VITA-49 meter packets, unit scaling), TCPIP-client (gui, station,
  udpport), TCPIP-keepalive, TCPIP-ping, TCPIP-info, TCPIP-version, TCPIP-display-pan (band), TCPIP-interlock, TCPIP-mic (input, list),
  SmartSDR-Status-Responses (interlock states, PTT sources, reasons), SmartSDR-Supported-Modes, Boolean-State,
  Known-API-Responses.
- xLib6000 by K3TZR, an open-source Swift port of FlexRadio's FlexLib: https://github.com/K3TZR/xLib6000. Used to confirm
  status field names, the transmit / ATU / interlock tokens, the command order a client sends on connect, the VITA-49 header
  layout, meter class code `0x8002` and the meter value scaling.
- Q-SYS TcpSocket reference: https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/TcpSocket.htm
- Q-SYS UdpSocket reference: https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/UdpSocket.htm
- Layout uses the project's Console theme v1.1 (`qsys-plugin-style-guide/theme.lua`), embedded unchanged.

FlexLib itself (FlexRadio's C# library) is distributed with SmartSDR rather than published online, so it was not read directly;
xLib6000 stands in for it where the wiki is silent. The FLEX-6600 figures used (4 receivers / slices, two SCUs, 100 W) are
from the WiMo dealer listing (https://www.wimo.com/en/fr-6601); FlexRadio's own product page could not be read from the build
environment.

## Changelog

- 1.1: restyled to the Console style guide v1.1 (vaporwave palette); no control or pin changes.
- 1.0: first release.
