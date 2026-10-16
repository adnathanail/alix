local colors = require("colors")
local settings = require("settings")

-- Helix key hints, shown beside the app menus (the second step of
-- items/menubar.lua's cycle) while the focused window is a Ghostty window
-- running Helix (`hx`).
--
-- Ghostty's zsh integration sets the window title to the running command
-- line, so a title of `hx …` means Helix is in the foreground. That is
-- checked whenever focus moves. Starting or quitting hx changes no focus, so
-- a zsh hook (../../default.nix) triggers `helix_change HELIX=on|off` too.
local hint = sbar.add("item", "helix.hint", {
  drawing = false,
  -- Hidden items skip their event handlers by default, which would leave
  -- it unable to show itself.
  updates = true,
  icon = {
    string = "HELIX",
    color = colors.black,
    font = { style = settings.font.style_map["Heavy"], size = 12.0 },
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    string = "i a insert · v select · w b e word · x line · d c delete/change"
      .. " · y p yank/paste · u U undo/redo · gg ge top/end · / n search"
      .. " · ␣ menu · :w :q",
    color = colors.black,
    font = { style = settings.font.style_map["Semibold"], size = 12.0 },
    padding_right = 10,
  },
  background = {
    color = colors.magenta,
    border_color = colors.black,
    border_width = 1,
    height = 26,
  },
  padding_left = 7,
})

-- swap_menus_and_spaces only toggles, and starts with the workspaces shown.
local menus_shown = false
local in_helix = false

local function render()
  hint:set({ drawing = menus_shown and in_helix })
end

local function check_focused()
  sbar.exec(
    "aerospace list-windows --focused --format '%{app-name}|%{window-title}'"
      .. " 2>/dev/null",
    function(out)
      local app, title = (out or ""):match("^([^|\n]*)|([^\n]*)")
      in_helix = app == "Ghostty"
        and (title == "hx" or title:find("^hx ") ~= nil)
      render()
    end
  )
end

sbar.add("event", "helix_change")
hint:subscribe("helix_change", function(env)
  in_helix = env.HELIX == "on"
  render()
end)

hint:subscribe(
  { "aerospace_workspace_change", "front_app_switched", "system_woke" },
  check_focused
)

hint:subscribe("swap_menus_and_spaces", function(_)
  menus_shown = not menus_shown
  render()
end)

check_focused()
