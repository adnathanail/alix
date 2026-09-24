-- Local addition: a Safari button for the current workspace's profile.
--
-- The profile is the focused AeroSpace workspace's, from ../profiles.lua
-- (generated from modules/interface/profiles.nix); elsewhere it's Safari's
-- default profile. The icon takes the profile's colour (white elsewhere).
-- Clicking focuses an open Safari window in that profile — one on this
-- workspace if there is one — or else opens a new one.
--
-- Safari can only open a profile's window from File → New Window, so that
-- is clicked via System Events, which needs Accessibility — SketchyBar has
-- it (on its stably-signed path) and osascript runs as its child. The new
-- window opens on the focused workspace; aerospace.nix's rules keep it
-- there. Safari starts each window's title with "<profile> — ", which is
-- how open windows are matched.

local colors = require("colors")
local settings = require("settings")
local profiles = require("profiles")

-- Safari's default profile, for workspaces without one of their own.
local default_profile = "Personal"

-- Gap between this pill and the eye's to its right (added first, as right
-- items go right to left).
sbar.add("item", "widgets.safari.padding", {
  position = "right",
  width = settings.group_paddings,
})

local safari = sbar.add("item", "widgets.safari", {
  position = "right",
  padding_left = 8,
  padding_right = 8,
  icon = {
    string = ":safari:",
    font = "sketchybar-app-font:Regular:16.0",
    color = colors.white,
    padding_left = 0,
    padding_right = 0,
    y_offset = -1,
  },
  label = { drawing = false },
})

sbar.add("bracket", "widgets.safari.bracket", { safari.name }, {
  background = { color = colors.bg1 }
})

local function focused_profile(callback)
  sbar.exec("aerospace list-workspaces --focused", function(out)
    local ws = out:match("[^\r\n]+") or ""
    callback(ws, profiles[ws])
  end)
end

local function new_window(profile)
  local item = "New " .. profile .. " Window"
  sbar.exec("osascript"
    .. " -e 'tell application \"Safari\" to activate'"
    .. " -e 'tell application \"System Events\" to tell process \"Safari\"'"
    .. " -e 'repeat until exists menu bar item \"File\" of menu bar 1'"
    .. " -e 'delay 0.1'"
    .. " -e 'end repeat'"
    .. " -e 'click menu item \"" .. item .. "\" of menu 1 of menu item"
    .. " \"New Window\" of menu 1 of menu bar item \"File\" of menu bar 1'"
    .. " -e 'end tell'")
end

safari:subscribe("mouse.clicked", function(_)
  focused_profile(function(ws, profile)
    local name = profile and profile.name or default_profile
    local prefix = name .. " — "
    sbar.exec(
      "aerospace list-windows --all"
        .. " --format '%{window-id}|%{workspace}|%{app-bundle-id}|%{window-title}'",
      function(out)
        local found, here = nil, nil
        for id, win_ws, app, title in out:gmatch("(%d+)|([^|\n]*)|([^|\n]*)|([^\n]*)") do
          if app == "com.apple.Safari" and title:sub(1, #prefix) == prefix then
            found = found or id
            if win_ws == ws then here = here or id end
          end
        end
        local id = here or found
        if id then
          sbar.exec("aerospace focus --window-id " .. id)
        else
          new_window(name)
        end
      end
    )
  end)
end)

local function update_colour()
  focused_profile(function(_, profile)
    safari:set({ icon = { color = profile and profile.colour or colors.white } })
  end)
end

-- aerospace_workspace_change is added by ./spaces.lua, loaded first.
safari:subscribe({ "aerospace_workspace_change", "system_woke" }, update_colour)
update_colour()
