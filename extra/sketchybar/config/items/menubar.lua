-- Local addition (not in FelixKratz's upstream config): toggles the native
-- macOS menu bar, as a way out if SketchyBar ever misbehaves.
--
-- Click flips System Settings' "Automatically hide and show the menu bar"
-- between Always and Never, via System Events (SketchyBar already has
-- Automation access to it for the calendar's Fantastical keystroke). The way
-- back is a matching icon in the native menu bar (../../menubar-return.m).
--
-- The bar is `topmost = "on"` (bar.lua): the status window level, one above
-- the native menu bar's, so hovering at the top of the screen reveals the
-- auto-hidden native bar *underneath* SketchyBar, where it can't be seen or
-- clicked. While the native bar is deliberately shown, SketchyBar hides
-- itself instead — lowering it below the native bar isn't enough, as the
-- native bar's background is transparent and SketchyBar shows through. It
-- keeps running while hidden, so the menubar_hide event still reaches it.
--
-- SketchyBar doesn't forward that change to the config, so the icon's state
-- is read at startup and after each click, not live — toggling in System
-- Settings instead leaves it stale until the next click or restart.

local colors = require("colors")
local settings = require("settings")

-- SF Symbol menubar.rectangle (codepoint found by rendering SF Pro).
local icon = utf8.char(0x1009F5)

local menubar = sbar.add("item", "widgets.menubar", {
  position = "right",
  icon = {
    string = icon,
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
    padding_left = 8,
    padding_right = 8,
  },
  label = { drawing = false },
  -- The config's default is "when_shown", and while the native bar is up the
  -- whole bar is hidden, so menubar_hide would never arrive.
  updates = true,
})

sbar.add("bracket", "widgets.menubar.bracket", { menubar.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.menubar.padding", {
  position = "right",
  width = settings.group_paddings
})

local function show_state(autohide)
  sbar.bar({ hidden = autohide and "off" or "on" })
end

-- `value` is AppleScript: "true", "false", or "not autohide menu bar" to
-- toggle. Reads the setting back afterwards so the state shown is the real
-- one.
local function set_autohide(value)
  sbar.exec(
    "osascript"
      .. " -e 'tell application \"System Events\" to tell dock preferences"
      .. " to set autohide menu bar to " .. value .. "'"
      .. " -e 'tell application \"System Events\" to get autohide menu bar"
      .. " of dock preferences'",
    function(result)
      show_state(result:match("true") ~= nil)
    end
  )
end

menubar:subscribe("mouse.clicked", function(env)
  set_autohide("not autohide menu bar")
end)

-- Fired by the native menu-bar icon (../../menubar-return.m) — the way back
-- when the native bar is showing. Always hides, never toggles.
sbar.add("event", "menubar_hide")
menubar:subscribe("menubar_hide", function(env)
  set_autohide("true")
end)

-- `defaults` avoids an Apple Event at startup. The key is absent until the
-- setting has been changed once, which means not hidden.
sbar.exec("defaults read -g _HIHideMenuBar 2>/dev/null", function(result)
  show_state(result:match("1") ~= nil)
end)
