# Cambridge Audio CXA81 plugin for Q-SYS

`Cambridge_CXA.qplug` controls a Cambridge Audio CXA81 integrated amplifier (also the CXA81 Mk II and the CXA61) over the
amplifier's rear-panel **RS-232C** port, using Cambridge Audio's published *CXA61 and CXA81 Serial Control Protocol v1.0*.

## What it can and can't do

The CXA's only documented control interface is that RS-232 protocol, and the protocol only covers these:

| Supported | How |
|---|---|
| Power on / standby | `#01,02,d`, with feedback |
| Mute on / off | `#01,04,d`, with feedback |
| Source select, next, previous | `#03,04,xx`, `#03,02`, `#03,03`, with feedback |
| Protocol and firmware version | `#13,01`, `#13,02` |
| Live feedback from the front panel and IR remote | The amp sends the new state on its own when power, mute or source change by any means |

**Not supported, because the protocol has no command for it:** volume, balance, tone, the setup menu (auto power down, USB
audio class), Bluetooth pairing and headphones. Volume stays on the amp's knob or its IR remote. The CXA has no Ethernet or
Wi-Fi control, so a network connection needs a serial-to-IP gateway (below). The CX **Control Bus** RCA sockets are only for
linking other Cambridge CX products, so the plugin doesn't use them.

## Install
1. Copy `Cambridge_CXA.qplug` to `Documents\QSC\Q-Sys Designer\Plugins`.
2. Restart Q-SYS Designer. The plugin appears under **Plugins > Audio > Cambridge Audio CXA81 (RS-232)**.
3. Drag it into the design. Use one instance per amplifier.

## Set up
1. In Properties, pick the **Model** (CXA81 / CXA81 Mk II, or CXA61). This sets the source buttons: the CXA81 has
   A1 Balanced, the CXA61 has MP3 instead.
2. Pick the **Connection**:
   - **Serial (RS-232 pin)** (default). The plugin gets an `RS-232` serial pin. Wire it to a serial port in the design (a
     Core's RS-232 port or a Q-SYS peripheral with one), and cable that port to the amp's RS232C socket. The plugin opens
     the port at **9600 baud, 8 data bits, no parity, 1 stop bit**. Serial ports only work on a Core, not in emulation.
   - **TCP (serial-to-IP gateway)**. For an amp that's out of reach of a Q-SYS serial port. Set the gateway's serial side
     to 9600 8N1 and its TCP side to raw pass-through, then type its IP and TCP port on the **Setup** page.
     The plugin reconnects every 5 s if the link drops.
3. The cable: the CXA manual and the protocol document don't give the RS232C connector's pinout or say whether it needs a
   straight or null-modem cable. If the Setup page shows **No reply from amplifier** with a good port, try the other cable
   type.
4. **Poll Interval** (default 10 s) only controls how quickly the plugin notices the amp has gone silent. Feedback doesn't
   wait for it, because the amp reports changes itself.

## Pages
| Page | What it shows |
|---|---|
| **Control** | **Power** (lit when on) with an On / Standby readout, **Mute**, ten source buttons in front-panel order, previous / next, and a source list. |
| **Setup** | The link (serial or gateway IP and port), Connect / Reopen, last error, model, protocol version, firmware version, Refresh, and the last message from the amp. |

The header on every page shows the model, power, source and mute at a glance, the Q-SYS Status and an Online LED.

![Control page](preview_Control.png)
![Setup page](preview_Setup.png)

**Properties:** Model, Connection, Poll Interval (s) (10), Debug Print (None / Errors / All).

**Pins:** most controls have pins. Useful ones for UCIs and scripts: `Power` (toggle), `PowerOn` / `PowerOff` (triggers),
`Mute`, `Source 1-10`, `SourceSelect` (source name), `SourceNext` / `SourcePrev`, `SourceCode` (the protocol's source
number, -1 when unknown), `Online`.

Source codes from the protocol document:

| Button | CXA81 | CXA61 |
|---|---|---|
| 1 | A1 Balanced (20) | A1 (00) |
| 2 | A1 (00) | A2 (01) |
| 3 | A2 (01) | A3 (02) |
| 4 | A3 (02) | A4 (03) |
| 5 | A4 (03) | D1 (04) |
| 6 | D1 (04) | D2 (05) |
| 7 | D2 (05) | D3 (06) |
| 8 | D3 (06) | MP3 (10) |
| 9 | USB Audio (16) | USB Audio (16) |
| 10 | Bluetooth (14) | Bluetooth (14) |

## How it works
- Messages are ASCII: `#`, a two-digit group, a comma, a two-digit command number, optional data, then a carriage return.
  The protocol document's own examples sometimes drop the leading zero (`#1,01`), so replies are matched by number and
  both forms are accepted.
- One command is sent at a time. The protocol says every command gets a reply or an error, so the plugin waits up to
  1.5 s for it before sending the next. Two unanswered commands in a row mark the amp offline (Status **Fault**,
  "No reply from amplifier"); it comes back online on the next reply.
- Quick repeated source presses are merged, so only the last one is sent. Next and previous presses are each sent.
- A pressed button shows the new state straight away, and the amp's reply confirms it (or puts it back after 2 s).
- Errors from the amp appear on the Setup page with the command that caused them: unknown group (`#00,01`), unknown
  command (`#00,02`), data out of range (`#00,03`), and "can't be actioned at this time" (`#00,04`). The protocol doesn't say
  when the amp returns `#00,04`, so when the amp is in standby the message says so as a likely reason.

## Not tested on hardware
This plugin was tested in a Lua 5.3 harness against a simulated CXA81 that follows the protocol document (serial and TCP,
with and without leading zeros, unsolicited updates, errors, going offline and back), and the previews are renderings of the
layout, not Designer screenshots. Check on site:
- Which commands the amp accepts in standby. The simulation refused mute and source in standby with `#00,04`; the real amp
  may behave differently.
- The RS-232 cable type (see Set up, step 3).
- The fonts and layout in Q-SYS Designer.
- The protocol document is for the CXA61 and CXA81. The CXA81 Mk II manual points to the same protocol, but it hasn't been
  checked on a Mk II.

## Sources
- Cambridge Audio, [CXA61 and CXA81 Serial Control Protocol v1.0](https://www.cambridgeaudio.com/sites/default/files/compliance/doc/AP366462%20CXA61%20CXA81%20Serial%20Control%20Protocol%20(1).pdf): serial settings, message format, commands, replies, source codes, errors, unsolicited updates.
- Cambridge Audio, [CXA61/81/81 Mk II manual](https://www.cambridgeaudio.com/row/en/manuals/cxa618181-mk-ii): inputs per model, the RS232C socket, Control Bus, and the pointer to the protocol.
- QSC, [Q-SYS SerialPorts](https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/SerialPorts.htm), [TcpSocket](https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/TcpSocket.htm) and [plugin functions](https://help.qsys.com/DeveloperHelp/Content/Standards_Definitions/Reserved_Functions.htm) (`GetPins` with `Domain = "serial"`).

Not affiliated with or endorsed by Cambridge Audio or QSC.
