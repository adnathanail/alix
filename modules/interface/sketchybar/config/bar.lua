local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  height = 40,
  -- Local change: above the native menu bar, which is never auto-hidden
  -- (../default.nix), so SketchyBar draws over it. items/menubar.lua hides
  -- the whole bar while the native one is deliberately shown.
  topmost = "on",
  color = colors.bar.bg,
  padding_right = 2,
  padding_left = 2,
})
