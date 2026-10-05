-- Hyper (⇧⌃⌥⌘) + a workspace's digit: go to that workspace and open a new
-- Safari window there in its profile, on the homepage. 1 is Safari's
-- default profile (Personal); the rest are the profiles in
-- modules/interface/profiles.nix, on their workspaces.
--
-- Generated: ./default.nix fills in the @…@ placeholders. Opening the window
-- is safari-new-window's job (../safari-new-window.nix), shared with
-- SketchyBar's Safari button; it clicks Safari's menu via System Events, on
-- Hammerspoon's Accessibility grant.

local aerospace = "@aerospace@/bin/aerospace"
local newWindow = "@safariNewWindow@/bin/safari-new-window"

-- workspace digit → Safari profile name
local profiles = @profiles@

local hyper = { "shift", "ctrl", "alt", "cmd" }

local M = { tasks = {} }

-- Kept in M.tasks while they run: an hs.task that's garbage-collected
-- mid-run is killed.
local function run(path, args, after)
  local task
  task = hs.task.new(path, function()
    M.tasks[task] = nil
    if after then after() end
  end, args)
  M.tasks[task] = true
  task:start()
end

function M.start()
  for ws, profile in pairs(profiles) do
    hs.hotkey.bind(hyper, ws, function()
      run(aerospace, { "workspace", ws }, function()
        run(newWindow, { profile })
      end)
    end)
  end
end

return M
