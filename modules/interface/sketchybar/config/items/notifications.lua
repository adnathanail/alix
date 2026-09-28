-- Local addition: a bell to the right of the clock that opens Notification
-- Centre, by clicking the native menu bar's clock (Control Center's menu
-- extra) through the same helpers/menus binary the app menus use. It finds
-- the clock by its AXIdentifier rather than the "Owner,Name" window alias,
-- as window names are redacted without Screen Recording. Needs only
-- SketchyBar's Accessibility grant (the helper runs as its child).

local colors = require("colors")
local settings = require("settings")

-- An SF Symbol rendered to an image, as items/menubar.lua does for its eye,
-- so the two look alike. Rendered at 25.5pt it's 29×31px: one image pixel
-- per Retina pixel at scale 0.5.
local image = os.getenv("HOME") .. "/Library/Caches/sketchybar/bell.png"

-- Gap between this pill and the right edge of the screen (added first, as
-- right items go right to left). The clock's own padding item
-- (items/calendar.lua) is the gap on its left.
sbar.add("item", "widgets.notifications.padding", {
  position = "right",
  width = settings.group_paddings,
})

local notifications = sbar.add("item", "widgets.notifications", {
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
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -i ControlCenter com.apple.menuextra.clock",
})

sbar.add("bracket", "widgets.notifications.bracket", { notifications.name }, {
  background = { color = colors.bg1 }
})

sbar.exec("f=\"" .. image .. "\"; mkdir -p \"$(dirname \"$f\")\";"
  .. " osascript -l JavaScript \"$CONFIG_DIR/helpers/render_symbol.js\" bell.fill"
  .. " \"$f\" " .. string.format("%06x", colors.white & 0xffffff) .. " 25.5"
  .. " >/dev/null",
  function()
    notifications:set({ background = { image = { string = image } } })
  end)
