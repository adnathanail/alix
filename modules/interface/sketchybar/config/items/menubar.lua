-- Local addition (not in FelixKratz's upstream config): one cycle through
-- workspaces → app menus → the native macOS menu bar → workspaces, driven by
-- the `bar_cycle` event. The switch by the app name (items/spaces.lua), the
-- app name itself (items/front_app.lua) and AeroSpace's ⌥` (aerospace.nix)
-- all trigger it. Showing the native bar is also a way out if SketchyBar
-- ever misbehaves.
--
-- The native bar is never auto-hidden (../../default.nix sets that), so
-- macOS keeps notification banners and the tiling area clear of it. The bar
-- is `topmost = "on"` (bar.lua): the status window level, one above the
-- native menu bar's, so SketchyBar simply draws over it. Showing the native
-- bar is then just hiding SketchyBar; the way back is either ⌥` or the
-- eye-with-a-slash icon in the native menu bar (../../menubar-return.m),
-- which triggers menubar_hide. SketchyBar keeps running while hidden, so
-- both events still reach it.

-- Not drawn; it only holds the subscriptions. The config's default is
-- updates = "when_shown", and while the native bar is up the whole bar is
-- hidden, so the events would never arrive.
local cycle = sbar.add("item", "menubar.cycle", {
  drawing = false,
  updates = true,
})

-- Whether the app menus are in place of the workspaces. Kept here because
-- swap_menus_and_spaces (items/menus.lua, items/spaces.lua) only toggles,
-- and nothing but this cycle triggers it.
local menus_shown = false
-- Whether the native bar is deliberately shown (and SketchyBar hidden).
local native_shown = false

local function swap_menus_and_spaces()
  menus_shown = not menus_shown
  sbar.trigger("swap_menus_and_spaces")
end

local function show_native(shown)
  native_shown = shown
  sbar.bar({ hidden = shown and "on" or "off" })
end

sbar.add("event", "bar_cycle")
cycle:subscribe("bar_cycle", function(env)
  if native_shown then
    show_native(false)
  elseif menus_shown then
    -- Back to the workspaces behind the scenes, so returning from the
    -- native bar lands at the start of the cycle.
    swap_menus_and_spaces()
    show_native(true)
  else
    swap_menus_and_spaces()
  end
end)

-- Fired by the native menu-bar icon (../../menubar-return.m).
sbar.add("event", "menubar_hide")
cycle:subscribe("menubar_hide", function(env)
  show_native(false)
end)
