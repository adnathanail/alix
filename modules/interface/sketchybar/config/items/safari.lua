-- Local addition: a Safari button for the current workspace's profile.
--
-- The profile is the focused AeroSpace workspace's, from ../profiles.lua
-- (generated from modules/interface/profiles.nix); elsewhere it's Safari's
-- default profile. The icon takes the profile's colour (white elsewhere).
-- Clicking focuses an open Safari window in that profile — one on this
-- workspace if there is one — or else opens a new one on the homepage.
--
-- New windows come from safari-new-window (../../safari-new-window.nix,
-- path substituted in by ../config.nix), which clicks Safari's menu via
-- System Events — on SketchyBar's Accessibility grant (its stably-signed
-- path), as osascript runs as its child. The new window opens on the
-- focused workspace; aerospace.nix's rules keep it there. Safari starts
-- each window's title with "<profile> — ", which is how open windows are
-- matched.

local colors = require("colors")
local profiles = require("profiles")

-- Safari's default profile, for workspaces without one of their own.
local default_profile = "Personal"

local safari = sbar.add("item", "safari", {
  position = "left",
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

sbar.add("bracket", "safari.bracket", { safari.name }, {
  background = { color = colors.bg1 }
})

local function focused_profile(callback)
  sbar.exec("aerospace list-workspaces --focused", function(out)
    local ws = out:match("[^\r\n]+") or ""
    callback(ws, profiles[ws])
  end)
end

local function new_window(profile)
  sbar.exec("@safariNewWindow@/bin/safari-new-window '" .. profile .. "'")
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
