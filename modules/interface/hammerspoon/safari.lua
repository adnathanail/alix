-- Hyper (⇧⌃⌥⌘) + a workspace's digit: go to that workspace, then focus a
-- Safari window in its profile — one there if there is one — or else open a
-- new one there, on the homepage. 1 is Safari's default profile (Personal);
-- the rest are the profiles in modules/interface/profiles.nix, on their
-- workspaces.
--
-- Generated: ./default.nix fills in the @…@ placeholders. The focusing and
-- opening is safari-window's job (../safari-window.nix), shared with
-- SketchyBar's Safari button; opening clicks Safari's menu via System
-- Events, on Hammerspoon's Accessibility grant.

local aerospace = "@aerospace@/bin/aerospace"
local safariWindow = "@safariWindow@/bin/safari-window"

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
        run(safariWindow, { profile })
      end)
    end)
  end
end

return M
