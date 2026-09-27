-- Local addition (not in FelixKratz's upstream config): toggles the native
-- macOS menu bar, as a way out if SketchyBar ever misbehaves.
--
-- The native bar is never auto-hidden (../../default.nix sets that), so
-- macOS keeps notification banners and the tiling area clear of it. The bar
-- is `topmost = "on"` (bar.lua): the status window level, one above the
-- native menu bar's, so SketchyBar simply draws over it. Showing the native
-- bar is then just hiding SketchyBar; the way back is a matching icon in the
-- native menu bar (../../menubar-return.m). SketchyBar keeps running while
-- hidden, so the menubar_hide event still reaches it.

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
-- No group-padding item after it, unlike the widgets: the Safari button to
-- its left (items/safari.lua) adds its own.

sbar.exec("f=\"" .. image .. "\"; mkdir -p \"$(dirname \"$f\")\";"
  .. " osascript -l JavaScript \"$CONFIG_DIR/helpers/render_symbol.js\" eye"
  .. " \"$f.tmp.png\" " .. string.format("%06x", colors.white & 0xffffff) .. " 25.5"
  .. " >/dev/null && sips -r 90 \"$f.tmp.png\" --out \"$f\" >/dev/null;"
  .. " rm -f \"$f.tmp.png\"",
  function()
    menubar:set({ background = { image = { string = image } } })
  end)

-- Whether the native bar is deliberately shown (and SketchyBar hidden).
local native_shown = false

local function show_native(shown)
  native_shown = shown
  sbar.bar({ hidden = shown and "on" or "off" })
end

menubar:subscribe("mouse.clicked", function(env)
  show_native(true)
end)

-- Fired by the native menu-bar icon (../../menubar-return.m) — the way back
-- when the native bar is showing.
sbar.add("event", "menubar_hide")
menubar:subscribe("menubar_hide", function(env)
  show_native(false)
end)

-- Fired by AeroSpace's ⌥` (aerospace.nix): the way back while the native
-- bar is showing, otherwise the usual swap between app menus and
-- workspaces. It can't just be swap_menus_and_spaces, as that would only
-- swap them in the hidden bar.
sbar.add("event", "menus_key")
menubar:subscribe("menus_key", function(env)
  if native_shown then
    show_native(false)
  else
    sbar.trigger("swap_menus_and_spaces")
  end
end)
