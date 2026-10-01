local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Workspaces come from AeroSpace, not native macOS Spaces. AeroSpace
-- triggers `aerospace_workspace_change` on every workspace and focus change
-- (wired up in ../../default.nix); each one re-reads the focused workspace
-- and every window's workspace from the `aerospace` CLI.

-- AeroSpace's persistent workspaces (the ones its key bindings name), read
-- once at startup. At login AeroSpace may still be starting, so retry
-- briefly; if it isn't installed at all, give up straight away.
local function list_workspaces()
  if not os.execute("command -v aerospace >/dev/null 2>&1") then return {} end
  for _ = 1, 20 do
    local handle = io.popen("aerospace list-workspaces --all 2>/dev/null")
    local names = {}
    for line in handle:read("*a"):gmatch("[^\r\n]+") do
      table.insert(names, line)
    end
    handle:close()
    if #names > 0 then return names end
    os.execute("sleep 0.5")
  end
  return {}
end

local workspaces = list_workspaces()
local spaces = {}
local paddings = {}
local brackets = {}
-- Whether the bar is in spaces mode (vs app menus); starts in spaces mode.
local shown = true

-- Workspaces shown by their app icons alone, without the name: 0 is
-- GitButler's (pinned in ../../../aerospace.nix).
local unnamed = { ["0"] = true }

-- Per-profile colours, keyed by workspace: ../profiles.lua, generated from
-- modules/interface/profiles.nix. The pill's background: a faint tint of it
-- when inactive, the full colour when active (with a white number, as red
-- clashes with the colours).
local accents = {}
for ws, profile in pairs(require("profiles")) do accents[ws] = profile.colour end
local tint_alpha = 0.3

for _, ws in ipairs(workspaces) do
  local space = sbar.add("item", "space." .. ws, {
    drawing = false,
    icon = {
      drawing = not unnamed[ws],
      font = { family = settings.font.numbers },
      string = ws,
      padding_left = 10,
      padding_right = 5,
      color = colors.white,
      highlight_color = accents[ws] and colors.white or colors.red,
    },
    label = {
      -- With no name, the icons need the name's left padding instead.
      padding_left = unnamed[ws] and 10 or 0,
      padding_right = 10,
      color = colors.grey,
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:16.0",
      y_offset = -1,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.bg1,
      border_width = 1,
      height = 26,
      border_color = colors.black,
    },
  })
  spaces[ws] = space

  -- Single item bracket for space items to achieve double border on highlight
  brackets[ws] = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
      border_width = 2
    }
  })

  -- Padding space
  paddings[ws] = sbar.add("item", "space.padding." .. ws, {
    drawing = false,
    width = settings.group_paddings,
  })

  space:subscribe("mouse.clicked", function(_)
    sbar.exec("aerospace workspace " .. ws)
  end)
end

-- Last state read from AeroSpace, so a mode swap can redraw without a query.
local focused = nil
local apps_by_ws = {}

local function render()
  for _, ws in ipairs(workspaces) do
    local selected = ws == focused
    local apps = apps_by_ws[ws] or {}
    -- Only the focused workspace and ones with windows, like i3's bar.
    local visible = shown and (selected or next(apps) ~= nil)

    local names = {}
    for app in pairs(apps) do table.insert(names, app) end
    table.sort(names)
    local icon_line = ""
    for _, app in ipairs(names) do
      icon_line = icon_line .. (app_icons[app] or app_icons["Default"])
    end
    if icon_line == "" then icon_line = " —" end

    spaces[ws]:set({
      drawing = visible,
      icon = { highlight = selected },
      label = { string = icon_line, highlight = selected },
      background = {
        color = not accents[ws] and colors.bg1
          or selected and accents[ws]
          or colors.with_alpha(accents[ws], tint_alpha),
        border_color = selected and colors.black or colors.bg2,
      },
    })
    paddings[ws]:set({ drawing = visible })
    brackets[ws]:set({
      background = { border_color = selected and colors.grey or colors.bg2 },
    })
  end
end

local function refresh()
  sbar.exec(
    "aerospace list-workspaces --focused; echo '--'; "
      .. "aerospace list-windows --all --format '%{workspace}|%{app-name}'",
    function(out)
      local head, windows = out:match("^(.-)\n%-%-\n(.*)$")
      if not head then return end
      focused = head:match("[^\r\n]+")
      apps_by_ws = {}
      for ws, app in windows:gmatch("([^|\r\n]+)|([^\r\n]+)") do
        apps_by_ws[ws] = apps_by_ws[ws] or {}
        apps_by_ws[ws][app] = true
      end
      render()
    end
  )
end

local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})
sbar.add("event", "aerospace_workspace_change")
space_window_observer:subscribe(
  { "aerospace_workspace_change", "front_app_switched", "system_woke" },
  refresh
)
space_window_observer:subscribe("swap_menus_and_spaces", function(_)
  shown = not shown
  render()
end)
refresh()

local spaces_indicator = sbar.add("item", {
  padding_left = -3,
  padding_right = 0,
  icon = {
    padding_left = 8,
    padding_right = 9,
    color = colors.grey,
    string = icons.switch.on,
  },
  label = {
    width = 0,
    padding_left = 0,
    padding_right = 8,
    -- The next step of items/menubar.lua's cycle, shown on hover.
    string = "Menus",
    color = colors.bg1,
  },
  background = {
    color = colors.with_alpha(colors.grey, 0.0),
    border_color = colors.with_alpha(colors.bg1, 0.0),
  }
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set({
    icon = currently_on and icons.switch.off or icons.switch.on,
    label = currently_on and "macOS bar" or "Menus",
  })
end)

spaces_indicator:subscribe("mouse.entered", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 1.0 },
        border_color = { alpha = 1.0 },
      },
      icon = { color = colors.bg1 },
      label = { width = "dynamic" }
    })
  end)
end)

local function collapse()
  spaces_indicator:set({
    background = {
      color = { alpha = 0.0 },
      border_color = { alpha = 0.0 },
    },
    icon = { color = colors.grey },
    label = { width = 0, }
  })
end

spaces_indicator:subscribe("mouse.exited", function(env)
  sbar.animate("tanh", 30, collapse)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  -- From the menus, this click hides the whole bar (items/menubar.lua), so
  -- mouse.exited never comes; collapse now, or the pill returns expanded.
  if spaces_indicator:query().label.value == "macOS bar" then collapse() end
  sbar.trigger("bar_cycle")
end)
