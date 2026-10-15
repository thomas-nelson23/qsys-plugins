# Deep Ocean: the design system for these plugins

Every plugin page follows the design system of [home-dash](https://github.com/thomas-nelson23/home-dashboard), Thomas's home server dashboard, in its current **Deep Ocean** look (`web/src/styles.css` with `web/src/theme.css` layered on top, read at commit `21a0b98`). This page says how each part of it was carried over to Q-SYS, and what Q-SYS can't draw.

[`theme.lua`](theme.lua) is the whole theme: one Lua block pasted into each `.qplug` above `GetControlLayout`. It uses only the layout properties in the Q-SYS [plugin reference](https://help.qsys.com/DeveloperHelp/Content/Standards_Definitions/Reserved_Functions.htm). The [Hue](../philips-hue/) and [UniFi](../unifi/) previews show it on real pages.

```lua
function GetControlLayout(props)
  local layout, graphics = {}, {}
  local ui = Theme.kit(layout, graphics)
  ui.page(600)
  ui.header("PHILIPS|HUE", "Control", "BridgeName", "Status", "Online", props["page_index"].Value)
  ui.section("Power", 8, 64, 200, 152)
  ui.button("Power", "POWER", 24, 96, 168, 64, "power")
  ui.hint("Pick a room, then use the pads.", 568)
  return layout, graphics
end
```

## Color

Q-SYS fills are solid, so home-dash's see-through glass and hairlines are pre-blended over the panel (or the field) they sit on.

| Theme name | RGB | home-dash source | Used for |
|---|---|---|---|
| `N.bg` | 2, 29, 46 | `--field` #021d2e | Page background: one flat field, no glows |
| `N.panel` | 6, 18, 27 | `.panel` glass, `rgba(4,12,18, .62 to .93)` | Panels and the header bar |
| `N.strip` | 8, 27, 37 | `--surface-hi` | Tiles and rows inside a panel |
| `N.well` | 4, 13, 19 | `.field input`, `rgba(0,0,0,.3)` | Readouts, fields, combo boxes, hint bar |
| `N.stroke` | 25, 41, 50 | `--glass-edge` | Panel and input edges |
| `N.hair` | 20, 31, 40 | `--hair` | Divider under a panel title |
| `N.lineStrong` | 16, 72, 91 | `--line-strong` | Button and editable-field outlines |
| `N.text` / `N.sub` / `N.dim` | 217, 238, 242 / 156, 199, 207 / 95, 114, 122 | `--text` / `--text-soft` / `--text-dim` | Values / labels / titles and notes |
| `S.ok` | 42, 212, 255 | `--cyan` #2ad4ff (Deep Ocean) | The only accent, and "good / online / on" |
| `S.fault` | 255, 42, 79 | `--red` #ff2a4f | Small signals (page number, panel mark, wordmark tail), errors, destructive buttons |
| `S.warn` | 255, 176, 32 | `--warn` #ffb020 | Warnings only, always with a label |

Rules carried over from home-dash: cyan is the one accent, red is for small signals and bad states, amber appears only with a label. Vendor brand colors are gone from the pages; each plugin keeps its brand color only as its schematic block color (`GetColor`). Where the color is the content (Hue and Nanoleaf swatches, quick colors, RGB and Kelvin faders), it stays.

## Type

Q-SYS ships a fixed font list, so each home-dash font has a stand-in:

| home-dash | Q-SYS | Why |
|---|---|---|
| Sora (text) | **Poppins** | The closest geometric sans on the list |
| JetBrains Mono (numbers, ids) | **Roboto Mono** | The only monospace on the list |
| Michroma (wordmark, display) | **Montserrat** Medium, upper case | The widest geometric face on the list |

Sizes follow home-dash at plugin scale: panel titles 10 SemiBold upper case (home-dash 10.5/600), labels 11, values 12, buttons 12 SemiBold (home-dash 12.5/600), wordmark 13.

## Components

| home-dash | Theme call | Notes |
|---|---|---|
| Top bar, numbered menu, `home`**`dash`** wordmark | `ui.header` | Cube mark, wordmark (text after `\|` is red), page number in red mono and page name in white like the numbered menu, device name, Q-SYS Status, Online dot |
| Front window's cyan-to-red top line | `ui.edge` | Drawn along the header's top edge |
| Wireframe cube backdrop | `ui.cube` | home-dash's own cube geometry (`Backdrop.jsx`), frozen at its starting pose, as an embedded SVG |
| `.panel` + `.panel-title` | `ui.section` | Glass card, 8 px corners, red mark, upper-case dim title, hairline below it. Content starts 32 px down |
| `.btn` | `"utility"` | Dark pill, soft legend, cyan-tinted outline |
| `.seg-btn.on`, `.tile-toggle.on` | `"primary"` | Dark pill that lights cyan when on |
| `.btn-accent` | `"secondary"`, `"ok"` | Cyan-tinted pill with a cyan legend |
| `.btn-danger`, `.banner-warn` | `"danger"`, `"warn"` | Tinted pill with a red or amber legend |
| `.tile-layouts button` | `"pad"` | Preset tiles with 8 px corners, cyan when on |
| `.led` | `ui.led` | Colored dot; off is hollow (transparent fill, dim ring) like `.led-off` |
| `.meter-track` / `.meter-fill` | `ui.meter` | Cyan bar on a faint track |
| `.field input` | `ui.field`, `ui.readout`, `ui.combo` | Dark well, 8 px corners; editable fields add the cyan-tinted outline |
| `.tile-value`, `.lcd-inline` | `ui.readout` | Numbers in mono |
| `.banner`, `.dim` notes | `ui.hint` | One help line at the bottom of each page |

Spacing: every page is 640 wide on an 8 px grid, corners are 8 px (Deep Ocean's `--radius`), and buttons are pills (corner radius half their height).

## What Q-SYS can't draw, and the stand-ins

| home-dash | Stand-in |
|---|---|
| Frosted glass (`backdrop-filter` blur) and translucent panels | Solid fills pre-blended to the color the glass shows over the field |
| Gradients (panel sheen, white-to-cyan value text, meter fill, window top line) | Flat colors; the top line is drawn in 24 px steps |
| Glows and shadows (LED glow, red `text-shadow`, panel drop shadow) | None; edges carry the depth |
| Letter-spacing on titles and labels | None; upper case and weight carry the label style |
| Sora, JetBrains Mono, Michroma | Poppins, Roboto Mono, Montserrat (above) |
| The turning, breathing, draggable cube; 120 to 240 ms transitions | A still cube; Q-SYS state changes are instant |
| Hover states | None (touch panels); on/off states are separate fills |
| A legend that changes color when a button lights | Q-SYS buttons have one `TextColor`, so a lit button uses cyan at 45% over the panel (`B.on`) instead of solid cyan with dark text |
| Status pill colors | The Q-SYS Status control colors itself (OK green, Fault red); only its shape is themed |

## Status

Not yet opened in Q-SYS Designer. The previews in each plugin folder are renderings of the layout tables with sample data, not Designer screenshots, so check fonts, the SVG cube and the transparent LED off color in Designer.
