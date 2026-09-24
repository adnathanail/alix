-- Local addition (not in FelixKratz's upstream config): toggles the native
-- macOS menu bar, as a way out if SketchyBar ever misbehaves.
--
-- Click flips System Settings' "Automatically hide and show the menu bar"
-- between Always and Never, via System Events (SketchyBar already has
-- Automation access to it for the calendar's Fantastical keystroke). The way
-- back is this same icon, so while the native bar is showing SketchyBar moves
-- down below it and rises above normal windows (`topmost = "window"`) —
-- otherwise windows cover it, since at its usual backstop level it sits
-- under them. SketchyBar would do the moving-down itself, but only when
-- `topmost` is off, so with it on the offset is applied here.
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
})

sbar.add("bracket", "widgets.menubar.bracket", { menubar.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.menubar.padding", {
  position = "right",
  width = settings.group_paddings
})

-- Height of the native menu bar: the main screen's top inset, which is also
-- how SketchyBar measures it (32pt on the notched built-in display).
local inset_cmd = "osascript -l JavaScript -e 'ObjC.import(\"AppKit\");"
  .. " var s = $.NSScreen.mainScreen;"
  .. " Math.round(s.frame.size.height - s.visibleFrame.origin.y"
  .. " - s.visibleFrame.size.height)'"

-- Icon bright while the native menu bar is showing, so it's obvious it's on.
local function show_state(autohide)
  menubar:set({ icon = { color = autohide and colors.grey or colors.white } })
  if autohide then
    sbar.bar({ topmost = "off", y_offset = 0 })
  else
    sbar.exec(inset_cmd, function(inset)
      sbar.bar({ topmost = "window", y_offset = tonumber(inset) or 32 })
    end)
  end
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
