--[[ Deep Ocean theme for Q-SYS plugins, v2.0 (2026-10-15)
     The home-dash design system (thomas-nelson23/home-dashboard, web/src/styles.css + theme.css)
     translated into what GetControlLayout can draw. Paste this block into a .qplug above
     GetControlLayout, then:

       function GetControlLayout(props)
         local layout, graphics = {}, {}
         local ui = Theme.kit(layout, graphics)
         ui.page(600)
         ui.header("PHILIPS|HUE", "Control", "BridgeName", "Status", "Online", 1)
         ui.section("Power", 8, 64, 200, 160)
         ui.button("Power", "POWER", 24, 96, 168, 48, "power")
         ...
         ui.hint("Pick a room, then use the pads.", 568)
         return layout, graphics
       end

     Every property used here is a documented GetControlLayout property:
     https://help.qsys.com/DeveloperHelp/Content/Standards_Definitions/Reserved_Functions.htm
     Guide: design/README.md in thomas-nelson23/qsys-plugins.
]]
local Theme = {}

Theme.W = 640   -- page width; every page is 640 wide
Theme.GRID = 8  -- positions and sizes snap to 8 (4 for fine alignment inside a row)

-- home-dash tokens. Glass and hairline colors are pre-blended over the panel or the
-- field, because Q-SYS draws solid fills (comments give the CSS each one comes from).
Theme.N = {
  bg      = { 2, 29, 46 },     -- --field #021d2e: the one flat deep-blue field
  panel   = { 6, 18, 27 },     -- .panel/.tile: rgba(--ink 4,12,18, .62-.93) glass over the field
  strip   = { 8, 27, 37 },     -- --surface-hi rgba(cyan, .045): a tile or row inside a panel
  rowAlt  = { 12, 24, 33 },    -- rgba(255,255,255,.025): alternate list row
  well    = { 4, 13, 19 },     -- .field input rgba(0,0,0,.3): readouts, fields, meters, hint bar
  stroke  = { 25, 41, 50 },    -- --glass-edge rgba(200,245,255,.1): panel and input edges
  hair    = { 20, 31, 40 },    -- --hair rgba(255,255,255,.055): dividers
  line    = { 10, 37, 50 },    -- --line rgba(cyan,.1)
  lineStrong = { 16, 72, 91 }, -- --line-strong rgba(cyan,.28): button and field outlines
  btn     = { 12, 24, 33 },    -- .btn background rgba(255,255,255,.025)
  btnOn   = { 25, 41, 50 },    -- .btn:hover, lifted
  ledOff  = { 0, 0, 0, 0 },    -- .led-off: hollow, only the ring shows
  white   = { 255, 255, 255 }, -- headings and big values (#fff)
  text    = { 217, 238, 242 }, -- --text #d9eef2
  sub     = { 156, 199, 207 }, -- --text-soft #9cc7cf: labels, secondary values
  dim     = { 95, 114, 122 },  -- --text-dim #5f727a: section titles, notes, units
  off     = { 58, 70, 80 },    -- --off #3a4650
  ink     = { 11, 15, 28 },    -- #0b0f1c: text on a solid cyan or white fill
}

-- Semantic colors: same meaning in every plugin. Cyan is also the only accent.
Theme.S = {
  ok    = { 42, 212, 255 },  -- --cyan #2ad4ff (Deep Ocean): good, online, on, the accent
  warn  = { 255, 176, 32 },  -- --warn #ffb020: attention only, always with a label
  fault = { 255, 42, 79 },   -- --red #ff2a4f: bad/offline, destructive actions, small signals
}

function Theme.mix(a, b, t)  -- t = 0 gives a, t = 1 gives b
  return { math.floor(a[1] + (b[1] - a[1]) * t + 0.5),
           math.floor(a[2] + (b[2] - a[2]) * t + 0.5),
           math.floor(a[3] + (b[3] - a[3]) * t + 0.5) }
end

-- home-dash has one accent, cyan. Theme.brand keeps the v1 field names so plugin code that
-- reads ui.B still works; the accent argument is accepted and ignored.
function Theme.brand()
  local cyan, panel = Theme.S.ok, Theme.N.panel
  return {
    accent = cyan,                        -- fader/knob/meter fill, on state of solid controls
    on     = Theme.mix(panel, cyan, 0.45), -- lit button fill (cyan at 45% over the panel)
    soft   = Theme.mix(panel, cyan, 0.08), -- --cyan-soft: .btn-accent and pad off state
    edge   = Theme.mix(panel, cyan, 0.45), -- rgba(cyan,.45): .btn-accent border
    dim    = Theme.mix(panel, cyan, 0.08), -- v1 name for soft
    pad    = Theme.mix(panel, cyan, 0.08), -- v1 name for soft
    ink    = cyan,                        -- cyan text (.lcd-inline, .bar-rest)
  }
end

-- Fonts. Q-SYS ships a fixed font list; these are the closest stand-ins for home-dash's
-- Sora (text), JetBrains Mono (numbers, ids) and Michroma (wordmark, display).
local FONT, MONO, DISPLAY = "Poppins", "Roboto Mono", "Montserrat"

local CUBE_SVG = "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9Ii0xMDAgLTEwMCAyMDAgMjAwIj48ZyBm"
  .. "aWxsPSJub25lIiBzdHJva2U9IiMyYWQ0ZmYiIHN0cm9rZS13aWR0aD0iNy4wIiBzdHJva2UtbGluZWNhcD0icm91bmQiPjxw"
  .. "YXRoIHN0cm9rZS1vcGFjaXR5PSIwLjE3NiIgZD0iTS0wLjAsODAuM0wtNzAuNyw0Mi4xTS0wLjAsODAuM0w3MC43LDQyLjFN"
  .. "MjMuNiw2Ny41TC00Ny4xLDI5LjNNLTIzLjYsNjcuNUw0Ny4xLDI5LjNNNDcuMSw1NC44TC0yMy42LDE2LjZNLTQ3LjEsNTQu"
  .. "OEwyMy42LDE2LjZNNzAuNyw0Mi4xTDAuMCwzLjlNLTcwLjcsNDIuMUwwLjAsMy45TTcwLjcsNDIuMUw3MC43LC00Mi4xTTcw"
  .. "LjcsNDIuMUwwLjAsMy45TTQ3LjEsMjkuM0w0Ny4xLC01NC44TTcwLjcsMTQuMEwwLjAsLTI0LjJNMjMuNiwxNi42TDIzLjYs"
  .. "LTY3LjVNNzAuNywtMTQuMEwwLjAsLTUyLjJNMC4wLDMuOUwwLjAsLTgwLjNNNzAuNywtNDIuMUwwLjAsLTgwLjNNLTcwLjcs"
  .. "NDIuMUwtNzAuNywtNDIuMU0tNzAuNyw0Mi4xTDAuMCwzLjlNLTQ3LjEsMjkuM0wtNDcuMSwtNTQuOE0tNzAuNywxNC4wTDAu"
  .. "MCwtMjQuMk0tMjMuNiwxNi42TC0yMy42LC02Ny41TS03MC43LC0xNC4wTDAuMCwtNTIuMk0wLjAsMy45TDAuMCwtODAuM00t"
  .. "NzAuNywtNDIuMUwwLjAsLTgwLjMiLz48cGF0aCBzdHJva2Utb3BhY2l0eT0iMC44IiBkPSJNLTAuMCwtMy45TC03MC43LC00"
  .. "Mi4xTS0wLjAsLTMuOUw3MC43LC00Mi4xTTIzLjYsLTE2LjZMLTQ3LjEsLTU0LjhNLTIzLjYsLTE2LjZMNDcuMSwtNTQuOE00"
  .. "Ny4xLC0yOS4zTC0yMy42LC02Ny41TS00Ny4xLC0yOS4zTDIzLjYsLTY3LjVNNzAuNywtNDIuMUwwLjAsLTgwLjNNLTcwLjcs"
  .. "LTQyLjFMMC4wLC04MC4zTS0wLjAsODAuM0wtMC4wLC0zLjlNLTAuMCw4MC4zTC03MC43LDQyLjFNLTIzLjYsNjcuNUwtMjMu"
  .. "NiwtMTYuNk0tMC4wLDUyLjJMLTcwLjcsMTQuME0tNDcuMSw1NC44TC00Ny4xLC0yOS4zTS0wLjAsMjQuMkwtNzAuNywtMTQu"
  .. "ME0tNzAuNyw0Mi4xTC03MC43LC00Mi4xTS0wLjAsLTMuOUwtNzAuNywtNDIuMU0tMC4wLDgwLjNMLTAuMCwtMy45TS0wLjAs"
  .. "ODAuM0w3MC43LDQyLjFNMjMuNiw2Ny41TDIzLjYsLTE2LjZNLTAuMCw1Mi4yTDcwLjcsMTQuME00Ny4xLDU0LjhMNDcuMSwt"
  .. "MjkuM00tMC4wLDI0LjJMNzAuNywtMTQuME03MC43LDQyLjFMNzAuNywtNDIuMU0tMC4wLC0zLjlMNzAuNywtNDIuMSIvPjwv"
  .. "Zz48L3N2Zz4="

local function merge(t, extra)
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end

function Theme.kit(layout, graphics)
  local N, S, B = Theme.N, Theme.S, Theme.brand()
  local ui = { N = N, S = S, B = B }

  local function g(t) table.insert(graphics, t) end
  local function box(x, y, w, h, fill, stroke, radius)
    g({ Type = "GroupBox", Fill = fill, StrokeColor = stroke or fill, StrokeWidth = stroke and 1 or 0,
        CornerRadius = radius or 0, Position = { x, y }, Size = { w, h } })
  end

  -- Static text. size: 10 hint/title, 11 label, 12 body, 13 emphasis
  function ui.label(text, x, y, w, h, align, size, color, style)
    g({ Type = "Label", Text = text, Font = FONT, FontStyle = style or "Regular", FontSize = size or 11,
        HTextAlign = align or "Right", Color = color or N.sub, Position = { x, y }, Size = { w, h or 20 } })
  end

  -- Page background: one flat field, no glows. Call first so it sits behind everything.
  function ui.page(h)
    box(0, 0, Theme.W, h, N.bg)
  end

  -- The wireframe cube from home-dash's backdrop, frozen at its starting pose
  -- (the frame home-dash shows when motion is reduced). s = size in px.
  function ui.cube(x, y, s)
    g({ Type = "Svg", Image = CUBE_SVG, Position = { x, y }, Size = { s, s } })
  end
  ui.sun = ui.cube  -- v1 name

  -- The front window's top edge: transparent > cyan > red > transparent, in 24 px steps.
  function ui.edge(x, y, w, base)
    local n = math.floor(w / 24)
    for i = 0, n - 1 do
      local t = (i + 0.5) / n
      local c
      if t < 0.25 then c = Theme.mix(base, S.ok, t / 0.25)
      elseif t < 0.75 then c = Theme.mix(S.ok, S.fault, (t - 0.25) / 0.5)
      else c = Theme.mix(S.fault, base, (t - 0.75) / 0.25) end
      box(x + i * 24, y, (i == n - 1) and (w - i * 24) or 24, 1, c)
    end
  end

  -- Top bar: cube, wordmark (Michroma stand-in; text after "|" is red, like "home|dash"),
  -- page number (red, mono) and page name like the numbered menu, device name, Status, Online LED.
  function ui.header(wordmark, pageName, nameCtl, statusCtl, ledCtl, pageNo)
    box(8, 8, 624, 48, N.panel, N.stroke, 8)
    ui.edge(16, 8, 608, N.stroke)
    ui.cube(18, 16, 32)
    local a, b = wordmark:match("^(.-)|(.*)$")
    a, b = string.upper(a or wordmark), string.upper(b or "")
    -- Q-SYS can't measure text, so the white part is right-aligned and the red part
    -- left-aligned on one seam; only the seam position is estimated (caps ~8.5 px at 13 px).
    local seam = 58 + math.floor(#a * 8.5 + 0.5)
    g({ Type = "Label", Text = a, Font = DISPLAY, FontStyle = "Medium", FontSize = 13, HTextAlign = "Right",
        Color = N.white, Position = { seam - 104, 20 }, Size = { 104, 24 }, Padding = 0 })
    if b ~= "" then
      g({ Type = "Label", Text = b, Font = DISPLAY, FontStyle = "Medium", FontSize = 13, HTextAlign = "Left",
          Color = S.fault, Position = { seam, 20 }, Size = { 104, 24 }, Padding = 0 })
    end
    if pageNo then
      g({ Type = "Label", Text = string.format("%02d", pageNo), Font = MONO, FontSize = 10, HTextAlign = "Left",
          Color = S.fault, Position = { 160, 22 }, Size = { 20, 20 } })
    end
    g({ Type = "Label", Text = string.upper(pageName), Font = FONT, FontStyle = "Medium", FontSize = 10,
        HTextAlign = "Left", Color = N.white, Position = { 180, 22 }, Size = { 96, 20 } })
    if nameCtl then ui.value(nameCtl, nil, 280, 20, 164, 24, { Color = N.panel, TextColor = N.sub, FontSize = 12 }) end
    if statusCtl then
      layout[statusCtl] = { PrettyName = "Status", Style = "Text", Position = { 452, 20 }, Size = { 140, 24 },
        Font = FONT, FontSize = 11, CornerRadius = 12 }
    end
    if ledCtl then ui.led(ledCtl, "Online", 602, 24, 16, "ok") end
  end

  -- Panel: glass card with a hairline edge, a small red signal, an uppercase dim title
  -- and a hairline under the title. Content starts 32 px below y.
  function ui.section(title, x, y, w, h)
    box(x, y, w, h, N.panel, N.stroke, 8)
    if title and title ~= "" then
      g({ Type = "GroupBox", StrokeColor = S.fault, StrokeWidth = 1, CornerRadius = 4,
          Position = { x + 12, y + 10 }, Size = { 8, 8 } })
      ui.label(string.upper(title), x + 26, y + 4, w - 38, 20, "Left", 10, N.dim, "SemiBold")
      box(x + 1, y + 27, w - 2, 1, N.hair)
    end
  end

  -- Tile inside a panel.
  function ui.strip(x, y, w, h)
    box(x, y, w, h, N.strip, N.hair, 8)
  end

  -- List row: every other row gets the faint lift.
  function ui.row(x, y, w, h, i)
    box(x, y, w, h, (i % 2 == 0) and N.rowAlt or N.strip, nil, 4)
  end

  -- Hint bar: one line of help per page, at the bottom.
  function ui.hint(text, y)
    g({ Type = "Label", Text = text, Font = FONT, FontSize = 10, HTextAlign = "Left", Color = N.dim, Fill = N.well,
        StrokeColor = N.hair, StrokeWidth = 1, CornerRadius = 8, Margin = 0, Padding = 8,
        Position = { 8, y }, Size = { 624, 24 } })
  end

  -- Buttons. kind (home-dash class in brackets):
  --   "primary"   toggle; dark pill, cyan when on            (.btn / .seg-btn.on)
  --   "secondary" cyan-tinted pill, cyan legend              (.btn-accent)
  --   "utility"   plain pill, soft legend                    (.btn)
  --   "pad"       preset tile, 8 px corners, cyan when on    (.tile-layouts button)
  --   "power"     the page's main action, bold               (.btn-accent, larger)
  --   "warn" / "danger" / "ok"  semantic tint and legend     (.banner-warn / .btn-danger)
  -- Pass ButtonStyle ("Toggle", "Momentary", "Trigger"...) in extra to match the control's ButtonType.
  local function tint(c, a) return Theme.mix(N.panel, c, a) end
  local KINDS = {
    primary   = { on = B.on, off = N.btn, text = N.text, stroke = N.lineStrong, pill = true, style = "SemiBold" },
    secondary = { on = B.on, off = B.soft, text = S.ok, stroke = B.edge, pill = true, style = "SemiBold" },
    utility   = { on = N.btnOn, off = N.btn, text = N.sub, stroke = N.lineStrong, pill = true, style = "SemiBold" },
    pad       = { on = B.on, off = N.strip, text = N.text, stroke = N.line, pill = false, style = "Medium" },
    power     = { on = B.on, off = N.btn, text = N.white, stroke = B.edge, pill = true, style = "Bold", size = 16 },
    warn      = { on = tint(S.warn, 0.25), off = tint(S.warn, 0.06), text = S.warn, stroke = tint(S.warn, 0.3), pill = true, style = "SemiBold" },
    danger    = { on = tint(S.fault, 0.25), off = tint(S.fault, 0.1), text = S.fault, stroke = tint(S.fault, 0.45), pill = true, style = "SemiBold" },
    ok        = { on = tint(S.ok, 0.25), off = B.soft, text = S.ok, stroke = B.edge, pill = true, style = "SemiBold" },
  }
  function ui.button(name, legend, x, y, w, h, kind, extra)
    local k = KINDS[kind or "primary"] or KINDS.primary
    h = h or 28
    layout[name] = merge({ PrettyName = name, Style = "Button", Legend = legend, Position = { x, y }, Size = { w, h },
      Color = k.on, OffColor = k.off, UnlinkOffColor = true, TextColor = k.text, StrokeColor = k.stroke, StrokeWidth = 1,
      Font = FONT, FontStyle = k.style, FontSize = k.size or 12,
      CornerRadius = k.pill and math.floor(math.min(w, h) / 2) or 8, ButtonVisualStyle = "Flat", Margin = 0, WordWrap = true }, extra)
  end

  -- Read-only readout: dark well, mono digits, no outline.
  function ui.readout(name, pretty, x, y, w, h, extra)
    layout[name] = merge({ PrettyName = pretty or name, Style = "Text", Position = { x, y }, Size = { w, h or 24 },
      Color = N.well, TextColor = N.text, Font = MONO, FontStyle = "Regular", FontSize = 12, HTextAlign = "Left",
      CornerRadius = 8, StrokeColor = N.well, StrokeWidth = 0, Padding = 4 }, extra)
  end

  -- Editable field: same well, plus the cyan-tinted outline so it reads as typeable.
  function ui.field(name, pretty, x, y, w, h, extra)
    ui.readout(name, pretty, x, y, w, h, merge({ StrokeColor = N.lineStrong, StrokeWidth = 1 }, extra))
  end

  -- Plain value text on the panel (names, secondary info). No well.
  function ui.value(name, pretty, x, y, w, h, extra)
    layout[name] = merge({ PrettyName = pretty or name, Style = "Text", Position = { x, y }, Size = { w, h or 20 },
      Color = N.panel, TextColor = N.text, Font = FONT, FontSize = 12, HTextAlign = "Left", StrokeWidth = 0,
      TextBoxStyle = "NoBackground" }, extra)
  end

  function ui.combo(name, pretty, x, y, w, h, extra)
    layout[name] = merge({ PrettyName = pretty or name, Style = "ComboBox", Position = { x, y }, Size = { w, h or 24 },
      Color = N.well, TextColor = N.text, Font = FONT, FontSize = 12, StrokeColor = N.stroke, StrokeWidth = 1,
      CornerRadius = 8 }, extra)
  end

  -- Fader: horizontal when w > h, vertical when h > w. Cyan unless the color is the content.
  function ui.fader(name, pretty, x, y, w, h, color, extra)
    layout[name] = merge({ PrettyName = pretty or name, Style = "Fader", Position = { x, y }, Size = { w, h },
      Color = color or B.accent }, extra)
  end

  -- Knob: secondary parameters only (trim, fade time, step). 36 or 48 square.
  function ui.knob(name, pretty, x, y, s, color, extra)
    layout[name] = merge({ PrettyName = pretty or name, Style = "Knob", Position = { x, y }, Size = { s or 36, s or 36 },
      Color = color or B.accent }, extra)
  end

  -- Status dot. kind: "ok" | "warn" | "fault" | "accent" | an RGB table (e.g. a color swatch).
  -- Off is hollow: only the dim ring shows (.led-off).
  function ui.led(name, pretty, x, y, s, kind, extra)
    local c = type(kind) == "table" and kind or (kind == "accent" and B.accent) or S[kind or "ok"] or S.ok
    layout[name] = merge({ PrettyName = pretty or name, Style = "Led", Position = { x, y }, Size = { s or 16, s or 16 },
      Color = c, OffColor = N.ledOff, UnlinkOffColor = true, StrokeColor = N.dim, StrokeWidth = 1, Margin = 3 }, extra)
  end

  -- Meter: thin cyan bar on a faint track, no built-in text box (put a readout next to it).
  function ui.meter(name, pretty, x, y, w, h, color, extra)
    layout[name] = merge({ PrettyName = pretty or name, Style = "Meter", MeterStyle = "Standard", Position = { x, y },
      Size = { w, h }, Color = color or B.accent, BackgroundColor = Theme.mix(N.panel, N.white, 0.06), CornerRadius = 2,
      ShowTextbox = false, StrokeWidth = 0 }, extra)
  end

  -- Hide a control but keep its pins.
  function ui.hide(name, pretty)
    layout[name] = { PrettyName = pretty or name, Style = "None", Position = { 0, 0 }, Size = { 0, 0 } }
  end

  return ui
end
