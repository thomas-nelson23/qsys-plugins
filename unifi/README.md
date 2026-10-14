# UniFi Network Monitor plugin for Q-SYS

`Unifi.qplug` reads one UniFi console per plugin instance (UDM Pro, UDM SE, UDR, UCG, Cloud Key Gen2+) over the console's
local UniFi Network API. It shows a scrollable client list with IP, MAC, connection and live bandwidth, internet and network
health, WAN throughput, speed test results, all UniFi devices with firmware and status, and switch/gateway ports with PoE.
It can also restart a device, power cycle a PoE port, authorize a guest and start a speed test.

## Install
1. Copy `Unifi.qplug` to `Documents\QSC\Q-Sys Designer\Plugins`.
2. Restart Q-SYS Designer. The plugin appears under **Plugins > Network > UniFi Network Monitor**.
3. Drag it into the design. Use one instance per UniFi console (and site).

## Set up
1. On the console, create an API key: **UniFi Network > Settings > Control Plane > Integrations > Create API Key**
   (Ubiquiti's help article calls this page "UniFi Network > Integrations"). The same page links the API documentation for
   your exact Network version. The key has the rights of the admin who created it, so use a read-only admin if you only need monitoring.
   Restart, PoE power cycle and guest authorization need an admin that can change the network.
2. The Core must reach the console on TCP 443. Use the console's LAN IP (for example the gateway address).
3. On the **Setup** page, enter the console IP and the API key. Leave **Site** blank to use the first site ("Default"),
   or type a site name.
4. **Save the key in the design.** Type it into the API Key field in Designer (not while emulating or running) and save,
   otherwise a re-deploy can clear it.
5. Optional: **Local user / Password** are only used if your Network version refuses the API key on the Extended Stats
   (legacy) endpoints. Use a local console account without 2FA. The Setup page shows which mode is in use.

**Connect / Refresh** reconnects after you change the IP, key or site.

## Pages
| Page | What it shows |
|---|---|
| **Network** | Internet LED and status, WAN IP, latency, gateway name and firmware, WAN uptime, WAN link (interface, speed, DNS). Live WAN down/up with meters. Last speed test (down, up, ping, time) and **Run Speed Test**. Gateway CPU, memory, load average and temperatures. Health LEDs for WAN, Internet, LAN, WLAN and VPN. Counts of clients (wired, wireless, guests), devices online, APs, switches and VPN users. |
| **Clients** | Filter (All, Wired, Wireless, Guests, VPN), sort (name, IP, bandwidth, connection, connected time) and search by name, hostname, IP, MAC or SSID. A 14-row table with Name, IP, MAC, Connection (SSID or switch port) and live Down/Up Mbps. Scroll with the scroll bar or the ^ / v buttons. Tap a name for details: signal and Wi-Fi experience, PHY link rate, radio and channel, uplink AP or switch port, network and VLAN, connected time and guest status, with **Authorize** / **Revoke** for guest clients. |
| **Devices** | Filter (All, Gateways, Switches, Access Points, Offline). A 10-row scrollable table with a state LED, name, model, IP, firmware (* = update available) and uptime / client count. Tap a device for MAC, state, adoption date, uptime, uplink device, CPU and memory meters, load average, uplink rate, each radio (band, standard, channel, width, retry %) and **Restart**. |
| **Ports** | Pick any device with ports (the gateway is first). A 12-row scrollable port table: link LED, port, name, speed / max speed, connector (RJ45, SFP+...), PoE standard, state and watts, and live Rx/Tx Mbps. Tap a port for a summary and **PoE Power Cycle**. |
| **Setup** | Console IP, API key, site, optional local user, Last Error, Network application version, site ID, which APIs are in use, counts and last update time. |

The header on every page shows the site name, the Q-SYS status (OK / Fault / Not Present / Initializing) and an Online LED.
**Restart** and **PoE Power Cycle** need a second press within 5 s.

**Properties:** Poll Interval (default 5 s), Extended Stats (On / Off, default On), WAN Meter Scale (default 1000 Mbps),
Debug Print (None / Errors / All).

**Pins:** WAN down/up Mbps, latency, gateway CPU and memory %, client and device counts, the Internet LED and the health LEDs
are output pins for control scripts and UCIs. `ClientSelectMAC` is an input pin that selects a client by MAC, IP or name.

## How it works
Two local APIs on the console are used. Both go to `https://<console>` with the API key in the `X-API-KEY` header.

**Official UniFi Network API** (Integration v1, base `/proxy/network/integration/v1`). This is Ubiquiti's documented API.
- `GET /info` (application version) and `GET /sites` (site ID and its internal name).
- `GET /sites/{siteId}/devices` (name, model, IP, MAC, state, firmware, update flag, features, interfaces), every 6 polls.
- `GET /sites/{siteId}/devices/{id}` for the selected device and the Ports device (ports with state, connector, speed, max speed
  and PoE; radios with standard, band, channel and width; uplink device; adoption date).
- `GET /sites/{siteId}/devices/{id}/statistics/latest` (uptime, CPU %, memory %, load averages, uplink tx/rx rate, radio retry %)
  for the gateway, the selected device, and one more device per poll in rotation.
- `GET /sites/{siteId}/clients` (type WIRED / WIRELESS / VPN / TELEPORT, name, IP, MAC, connected time, uplink device, guest
  access). Lists are read in pages of 200 using `offset` and `limit` until `totalCount` is reached.
- `GET /sites/{siteId}/wans` (WAN names).
- Actions: `POST .../devices/{id}/actions` with `{"action":"RESTART"}`, `POST .../devices/{id}/interfaces/ports/{idx}/actions`
  with `{"action":"POWER_CYCLE"}`, and `POST .../clients/{id}/actions` with `AUTHORIZE_GUEST_ACCESS` (plus `timeLimitMinutes`)
  or `UNAUTHORIZE_GUEST_ACCESS`.

**Extended Stats (legacy Network API, base `/proxy/network/api/s/<site>`).** The official API has no per-client bandwidth or
signal, no WAN IP, latency or speed test, no subsystem health and no per-port throughput. Those come from the older API that
the UniFi web app itself uses. Ubiquiti does not document it, so it is optional and can be turned off in Properties.
- `GET /stat/health`: per-subsystem status. `wan` gives WAN IP, gateway CPU/memory, DNS servers and WAN `rx_bytes-r` /
  `tx_bytes-r`; `www` gives latency, internet uptime and the last speed test (`xput_down`, `xput_up`, `speedtest_ping`,
  `speedtest_lastrun`); `lan`, `wlan` and `vpn` give counts and rates.
- `GET /stat/sta`: per-client `tx_bytes-r` / `rx_bytes-r`, signal, satisfaction, link rates, SSID, channel, switch port,
  network, VLAN and hostname. Matched to the official client list by MAC.
- `GET /stat/device/<mac>` for the Ports device each poll, and `GET /stat/device` for all devices every 6 polls: port names,
  per-port rates and PoE watts, temperatures, client counts, the WAN interface and the target firmware version.
- `POST /cmd/devmgr` with `{"cmd":"speedtest"}` starts a speed test. Results appear on the next polls.
- It first tries the API key. If that gets 401 and a local user is set, it logs in once with `POST /api/auth/login`, then
  sends the `TOKEN` cookie and the `X-CSRF-Token` header. It logs in again only when the session expires. If it is refused
  and no user is set, it retries every 60 polls, and the official data keeps working.

**Units:** `*_bytes-r` values are bytes per second and are shown in Mbps (x8). The official `txRateBps` / `rxRateBps` are
treated as bits per second. WAN throughput uses the legacy `wan` health rates when available, otherwise the gateway's uplink
statistics.

**One request at a time:** a new poll is skipped if the previous round is still running, so a slow console never builds a
backlog. A normal poll is about 10 requests.

## Limitations / not tested on hardware
**This plugin has not been run against a real UniFi console or a real Q-SYS Core.** The logic was tested in a Lua 5.3 harness
with mocked Q-SYS controls, `HttpClient`, `Timer` and `rapidjson`, against a simulated UDM Pro (4 devices including an offline
AP, a 26-port PoE switch, 45 clients with paging, 2 sites). The tests covered:
- connect, site lookup by name, a wrong site, a wrong API key (401) and the console going offline and coming back
- client paging, sorting, filtering, search, scrolling, selection and guest authorization
- device list, filters, details, statistics, radios and restart with confirmation
- ports on the gateway and the switch, PoE, port names and rates, and power cycle
- Extended Stats with the API key, refused with no user (official data still works), the local-login fallback, and turned off
- speed test, and the request budget per poll

The layout previews (`preview_*.png`) are a close rendering of the layout with test data, not a Designer screenshot.

Check these on site:
- **HTTPS certificate:** the console uses a self-signed certificate. Q-SYS's HttpClient documentation covers `https://` and
  TLS 1.0-1.3 but says nothing about certificate checks. If the Core rejects the certificate, Last Error shows the HttpClient
  error on every poll. This is the first thing to confirm.
- **API key on the legacy endpoints:** recent Network versions accept the API key there (the open-source `unpoller` library
  relies on this), but Ubiquiti does not document it. The Setup page shows whether it was accepted or the local login is used.
- **Bandwidth direction:** client Down uses `tx_bytes-r` (sent from the AP or switch to the client) and Up uses `rx_bytes-r`.
  Compare one busy client against the UniFi app and swap the meaning if your version reports them the other way.
- **Rate units of the official API:** `txRateBps` / `rxRateBps` are taken as bits per second. The spec gives no unit.
  They are only used when Extended Stats are off or refused.
- **Gateway uplink = WAN:** with Extended Stats off, WAN throughput comes from the gateway's uplink statistics. Confirm that
  matches the WAN in the UniFi app on your console.
- **Password field:** Q-SYS text fields are not masked, so anyone with access to the design can read the local password.
  Prefer the API key alone, and if you need the local user, make it a read-only account.
- **Layout styling:** check that Designer renders the layout the same way (flat buttons, rounded corners, meters, runtime
  `.Color` on LEDs and the vertical scroll faders).

Not included:
- Cloud access (Site Manager API, api.ui.com). This plugin is local only.
- Historical charts, DPI / app traffic, firewall, VPN, Wi-Fi and network configuration, client blocking and firmware upgrades.
  Use the UniFi app for those.
- Devices pending adoption, hotspot vouchers, and UniFi Protect, Access or Talk.

## Sources
- UniFi Network API documentation (official): https://developer.ui.com/network/v10.6.106/gettingstarted. The same reference
  is served by each console for its own version under UniFi Network > Integrations.
- Ubiquiti Help Center, "Getting Started with the Official UniFi API": https://help.ui.com/hc/en-us/articles/30076656117655
- UniFi Network API OpenAPI spec, version 10.1.89 (a copy of the spec the console serves at
  `/proxy/network/api-docs/integration.json`), from the `go-unifi` project: https://github.com/jonshaffer/go-unifi.
  All official endpoints, field names, enums, filters, page limits and action bodies above were taken from this file.
- `unpoller/unifi` Go library v5.31.0 (community, widely used), for the legacy endpoints, their field names, the
  `/api/auth/login` + `X-CSRF-Token` flow and API-key use on legacy endpoints: https://github.com/unpoller/unifi
- Q-SYS HttpClient reference (Download/Upload, Headers, the `headers` argument of EventHandler, HTTPS and TLS):
  https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/HttpClient.htm

developer.ui.com is a script-rendered site, and its pages could not be read from the build environment, so the endpoint
details were taken from the console's own OpenAPI spec (via go-unifi) rather than the web pages. The legacy API is not
documented by Ubiquiti. Its field names come from `unpoller` and may change between Network versions. The Q-SYS layout
properties (`GroupBox`/`Label` graphics, `Style`, `Meter`, `OffColor`, `CornerRadius`) follow the conventions of this
project's Hue and Nanoleaf plugins, so check them in Designer.
