-- Local addition: the icons of the apps with something unread (Slack,
-- MailMate) and their combined count, hidden while there's nothing.
--
-- Hammerspoon does the reading and sets this item's drawing, icons and
-- label directly (modules/interface/hammerspoon/notifications.lua). A click asks it
-- for a native macOS menu listing each app's count; choosing a line focuses
-- that app. Both requests go through Hammerspoon's URL scheme, with `open -g`
-- so Hammerspoon isn't brought forward.

local colors = require("colors")

local notifications = sbar.add("item", "widgets.notifications", {
  position = "right",
  drawing = false,
  icon = {
    font = "sketchybar-app-font:Regular:16.0",
    color = colors.red,
    y_offset = -1,
    -- The pill's inner edges, left of the icons and right of the count.
    -- With no count showing, the icon's own right padding is the edge, so
    -- Hammerspoon swaps it along with label.drawing.
    padding_left = 8,
  },
  label = { drawing = false, padding_right = 8 },
  background = { color = colors.bg1 },
})

notifications:subscribe("mouse.clicked", function(_)
  sbar.exec("open -g 'hammerspoon://notifications-menu'")
end)

-- SketchyBar starts with the item hidden (every rebuild restarts it), and
-- Hammerspoon only pushes on a change, so ask for the current state.
sbar.exec("open -g 'hammerspoon://notifications-refresh'")
