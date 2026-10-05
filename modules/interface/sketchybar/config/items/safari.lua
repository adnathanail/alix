-- Local addition: a Safari button for the current workspace's profile.
--
-- The profile is the focused AeroSpace workspace's, from ../profiles.lua
-- (generated from modules/interface/profiles.nix); elsewhere it's Safari's
-- default profile. The icon takes the profile's colour (white elsewhere).
-- Clicking runs safari-window (../../safari-window.nix, path substituted in
-- by ../config.nix): it focuses an open Safari window in that profile — one
-- on this workspace if there is one — or else opens a new one on the
-- homepage. Opening clicks Safari's menu via System Events, on SketchyBar's
-- Accessibility grant (its stably-signed path), as osascript runs as its
-- child. Hammerspoon's hyper+digit hotkeys do the same.

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

safari:subscribe("mouse.clicked", function(_)
  focused_profile(function(_, profile)
    local name = profile and profile.name or default_profile
    sbar.exec("@safariWindow@/bin/safari-window '" .. name .. "'")
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
