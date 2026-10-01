-- Local addition: a bell with the unread total from Slack and MailMate,
-- hidden while there's nothing.
--
-- Hammerspoon does the reading and sets this item's drawing and label
-- directly (modules/interface/hammerspoon/notifications.lua). A click asks it
-- for a native macOS menu listing each app's count; choosing a line focuses
-- that app. Both requests go through Hammerspoon's URL scheme, with `open -g`
-- so Hammerspoon isn't brought forward.

local icons = require("icons")
local colors = require("colors")

local notifications = sbar.add("item", "widgets.notifications", {
  position = "right",
  drawing = false,
  icon = {
    string = icons.bell,
    color = colors.red,
  },
  label = { drawing = false },
  background = { color = colors.bg1 },
})

notifications:subscribe("mouse.clicked", function(_)
  sbar.exec("open -g 'hammerspoon://notifications-menu'")
end)

-- SketchyBar starts with the item hidden (every rebuild restarts it), and
-- Hammerspoon only pushes on a change, so ask for the current state.
sbar.exec("open -g 'hammerspoon://notifications-refresh'")
