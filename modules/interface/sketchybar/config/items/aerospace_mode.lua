local colors = require("colors")
local settings = require("settings")

-- AeroSpace key hints: one pill for service mode, one while Option is held.

-- Shown only while AeroSpace is in service mode (⌥⇧;), as a reminder of
-- the one-key commands it offers. AeroSpace has no mode-change callback, so
-- its bindings trigger `aerospace_mode_change MODE=<mode>` themselves
-- (../../../aerospace.nix).
local mode = sbar.add("item", "aerospace.mode", {
  drawing = false,
  -- Hidden items skip their event handlers by default, which would leave
  -- it unable to show itself.
  updates = true,
  icon = {
    string = "SERVICE",
    color = colors.black,
    font = { style = settings.font.style_map["Heavy"], size = 12.0 },
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    string = "F float · R reset · ⌥⇧HJKL join · esc reload",
    color = colors.black,
    font = { style = settings.font.style_map["Semibold"], size = 12.0 },
    padding_right = 10,
  },
  background = {
    color = colors.red,
    border_color = colors.black,
    border_width = 1,
    height = 26,
  },
  padding_right = 7,
})

sbar.add("event", "aerospace_mode_change")
mode:subscribe("aerospace_mode_change", function(env)
  mode:set({ drawing = env.MODE == "service" })
end)

-- Shown while Option is held on its own: the main-mode ⌥ shortcuts. The
-- `aerospace_option_hint HELD=on|off` event comes from ../../option-hint.c.
local option_hint = sbar.add("item", "aerospace.option_hint", {
  drawing = false,
  updates = true,
  icon = {
    string = "⌥",
    color = colors.black,
    font = { style = settings.font.style_map["Heavy"], size = 13.0 },
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    string = "§ 1–9 workspace · ⇧§ ⇧1–9 send · HJKL focus · ⇧HJKL move · "
      .. "/ tiles · , accordion · - = resize · ⇥ back · ` bar · ⇧; service",
    color = colors.black,
    font = { style = settings.font.style_map["Semibold"], size = 12.0 },
    padding_right = 10,
  },
  background = {
    color = colors.blue,
    border_color = colors.black,
    border_width = 1,
    height = 26,
  },
  padding_right = 7,
})

sbar.add("event", "aerospace_option_hint")
option_hint:subscribe("aerospace_option_hint", function(env)
  option_hint:set({ drawing = env.HELD == "on" })
end)
