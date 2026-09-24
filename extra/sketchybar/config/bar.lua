local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  height = 40,
  -- Local change: above the (auto-hidden) native menu bar, so hovering at
  -- the top of the screen can't reveal it over SketchyBar. items/menubar.lua
  -- hides the whole bar while the native one is deliberately shown.
  topmost = "on",
  color = colors.bar.bg,
  padding_right = 2,
  padding_left = 2,
})
