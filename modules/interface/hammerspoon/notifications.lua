-- Unread counts from Slack and MailMate, shown by SketchyBar's
-- widgets.notifications item (modules/interface/sketchybar/config/items/
-- notifications.lua), which is always on screen. Clicking it opens a native
-- menu from here — one line per app, choosing one focuses that app.
--
-- Hammerspoon does the reading because it already has Accessibility:
--   * Slack sets an ordinary Dock badge, read with lsappinfo. (Its
--     `-only StatusLabel` comes back empty on this macOS, so the full
--     `-long` dump is searched instead.)
--   * MailMate draws its Dock icon itself, so it has no badge for anything
--     to read. Its own menu-bar counters do carry their counts as titles,
--     read here through Accessibility. The first of them is taken as the
--     unread count, so the unread counter should be the only one with "Show
--     in menu bar" ticked in MailMate's counter settings.
--
-- The two talk without IPC: Hammerspoon runs `sketchybar --set` when the
-- counts change, and SketchyBar opens hammerspoon:// URLs (`open -g`, so
-- Hammerspoon isn't brought forward) to ask for the menu, or for a fresh
-- push when SketchyBar restarts and loses the item's state.

local M = {}

-- Home Manager's profile link, so it survives SketchyBar updates.
local sketchybar = "/etc/profiles/per-user/" .. os.getenv("USER") .. "/bin/sketchybar"
local item = "widgets.notifications"
local interval = 5 -- seconds between checks

-- A badge string, or nil when the app isn't running or has nothing.
local function dockBadge(bundleID)
  if not hs.application.get(bundleID) then return nil end
  local out = hs.execute("/usr/bin/lsappinfo info -long -app " .. bundleID)
  local label = out and out:match('"StatusLabel"={ "label"="([^"]*)" }')
  if label == nil or label == "" then return nil end
  return label
end

local function mailmateUnread(bundleID)
  local app = hs.application.get(bundleID)
  if not app then return nil end
  local bar = hs.axuielement.applicationElement(app):attributeValue("AXExtrasMenuBar")
  local first = bar and (bar:attributeValue("AXChildren") or {})[1]
  local count = first and tonumber(first:attributeValue("AXTitle"))
  if not count or count == 0 then return nil end
  return tostring(count) .. " unread"
end

local sources = {
  { name = "Slack", bundleID = "com.tinyspeck.slackmacgap", read = dockBadge },
  { name = "MailMate", bundleID = "com.freron.MailMate", read = mailmateUnread },
}

-- { {source, badge}, … } for the apps with something, as of the last check.
local current = {}
local pushed = nil -- the last `sketchybar --set` arguments, to skip repeats

local function push()
  local total, numeric = 0, true
  for _, entry in ipairs(current) do
    local n = tonumber(entry.badge:match("^%d+"))
    if n then total = total + n else numeric = false end
  end
  local args = { "--set", item }
  if #current == 0 then
    table.insert(args, "drawing=off")
  else
    -- A badge like Slack's "•" (unread, no mentions) has no number; with
    -- one of those, any total would understate, so show just the bell.
    table.insert(args, "drawing=on")
    table.insert(args, "label=" .. ((numeric and total > 0) and tostring(total) or ""))
    table.insert(args, "label.drawing=" .. ((numeric and total > 0) and "on" or "off"))
  end
  local key = table.concat(args, " ")
  if key == pushed then return end
  pushed = key
  hs.task.new(sketchybar, nil, args):start()
end

local function check()
  local found = {}
  for _, source in ipairs(sources) do
    local ok, badge = pcall(source.read, source.bundleID)
    if ok and badge then
      table.insert(found, { source = source, badge = badge })
    end
  end
  current = found
  push()
end

-- Off-screen status item: only used for its popupMenu.
local menu = hs.menubar.new(false)

local function popup()
  check()
  local entries = {}
  for _, entry in ipairs(current) do
    local bundleID = entry.source.bundleID
    table.insert(entries, {
      title = entry.source.name .. " — " .. entry.badge,
      fn = function() hs.application.launchOrFocusByBundleID(bundleID) end,
    })
  end
  if #entries == 0 then
    table.insert(entries, { title = "No notifications", disabled = true })
  end
  menu:setMenu(entries)
  -- Drop down from the bottom of the bar (40pt, ../sketchybar/config/bar.lua),
  -- under the pointer.
  local pointer = hs.mouse.absolutePosition()
  local screen = hs.mouse.getCurrentScreen():fullFrame()
  menu:popupMenu({ x = pointer.x, y = screen.y + 40 })
end

function M.start()
  M.timer = hs.timer.doEvery(interval, check)
  hs.urlevent.bind("notifications-menu", popup)
  hs.urlevent.bind("notifications-refresh", function()
    pushed = nil
    check()
  end)
  check()
end

return M
