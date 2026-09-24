-- Local addition (not in FelixKratz's upstream config): toggles the native
-- macOS menu bar, as a way out if SketchyBar ever misbehaves.
--
-- Click flips System Settings' "Automatically hide and show the menu bar"
-- between Always and Never, via System Events (SketchyBar already has
-- Automation access to it for the calendar's Fantastical keystroke). The way
-- back is a matching icon in the native menu bar (../../menubar-return.m).
--
-- The bar is `topmost = "on"` (bar.lua): the status window level, one above
-- the native menu bar's, so hovering at the top of the screen reveals the
-- auto-hidden native bar *underneath* SketchyBar, where it can't be seen or
-- clicked. While the native bar is deliberately shown, SketchyBar hides
-- itself instead — lowering it below the native bar isn't enough, as the
-- native bar's background is transparent and SketchyBar shows through. It
-- keeps running while hidden, so the menubar_hide event still reaches it.
--
-- SketchyBar doesn't forward that change to the config, so whether the bar
-- is hidden is set at startup and after each click, not live — toggling in
-- System Settings instead leaves it out of step until the next click or
-- restart.

local colors = require("colors")

-- The icon is the SF Symbol "eye" turned upright, to keep the widget narrow.
-- SketchyBar can't rotate text, so rather than an SF Pro glyph it's an image:
-- helpers/render_symbol.js draws the symbol (by name) in the bar's text
-- colour, sips turns it 90°, and it's shown as the item's background.
-- Re-rendered into the cache on every start, so it follows colors.white.
local image = os.getenv("HOME") .. "/Library/Caches/sketchybar/eye-vertical.png"

-- Rendered at 25.5pt the eye is 40×26px, so upright at scale 0.5 it's
-- 13×20pt with exactly one image pixel per Retina pixel. SketchyBar scales
-- images without smoothing, so any other ratio comes out jagged.
--
-- The item sizes to the image; its padding is 8pt a side (the default 5,
-- plus the 3pt of icon padding the other widgets have) so its pill matches
-- theirs. Not a fixed `width`: SketchyBar then stops leaving room for the
-- padding when placing neighbours, and the pill overlaps them.
local menubar = sbar.add("item", "widgets.menubar", {
  position = "right",
  padding_left = 8,
  padding_right = 8,
  icon = { drawing = false },
  background = {
    drawing = true,
    color = colors.transparent,
    border_width = 0,
    image = {
      scale = 0.5,
      border_width = 0,
      corner_radius = 0,
    },
  },
  label = { drawing = false },
  -- The config's default is "when_shown", and while the native bar is up the
  -- whole bar is hidden, so menubar_hide would never arrive.
  updates = true,
})

sbar.add("bracket", "widgets.menubar.bracket", { menubar.name }, {
  background = { color = colors.bg1 }
})
-- No group-padding item after it, unlike the widgets: the Spotify cover to
-- its left has no pill, so the cover's own padding already makes the usual
-- 5pt gap.

sbar.exec("f=\"" .. image .. "\"; mkdir -p \"$(dirname \"$f\")\";"
  .. " osascript -l JavaScript \"$CONFIG_DIR/helpers/render_symbol.js\" eye"
  .. " \"$f.tmp.png\" " .. string.format("%06x", colors.white & 0xffffff) .. " 25.5"
  .. " >/dev/null && sips -r 90 \"$f.tmp.png\" --out \"$f\" >/dev/null;"
  .. " rm -f \"$f.tmp.png\"",
  function()
    menubar:set({ background = { image = { string = image } } })
  end)

local function show_state(autohide)
  sbar.bar({ hidden = autohide and "off" or "on" })
end

-- `value` is AppleScript: "true", "false", or "not autohide menu bar" to
-- toggle. Reads the setting back afterwards so the state shown is the real
-- one.
local function set_autohide(value)
  sbar.exec(
    "osascript"
      .. " -e 'tell application \"System Events\" to tell dock preferences"
      .. " to set autohide menu bar to " .. value .. "'"
      .. " -e 'tell application \"System Events\" to get autohide menu bar"
      .. " of dock preferences'",
    function(result)
      show_state(result:match("true") ~= nil)
    end
  )
end

menubar:subscribe("mouse.clicked", function(env)
  set_autohide("not autohide menu bar")
end)

-- Fired by the native menu-bar icon (../../menubar-return.m) — the way back
-- when the native bar is showing. Always hides, never toggles.
sbar.add("event", "menubar_hide")
menubar:subscribe("menubar_hide", function(env)
  set_autohide("true")
end)

-- `defaults` avoids an Apple Event at startup. The key is absent until the
-- setting has been changed once, which means not hidden.
sbar.exec("defaults read -g _HIHideMenuBar 2>/dev/null", function(result)
  show_state(result:match("1") ~= nil)
end)
