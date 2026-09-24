-- Local addition (not in FelixKratz's upstream config): animate the bar back
-- in after unlocking the screen. Adapted from his bash version,
-- github.com/nicolas-martin/awesome-sketchybar
--   plugins/Simple-LockUnlock-Animation.md
-- to Lua and to this bar: 40pt tall rather than 32, no centre notch gap (his
-- animation ends by opening one), and it settles on the opaque colors.bar.bg
-- with no blur rather than his translucent blurred bar.
--
-- Locking snaps the bar out of sight: up off the top of the screen, pulled
-- 200pt past both edges, fully transparent. Unlocking animates it back.
-- Inside sbar.animate every sbar.bar call joins one message, so setting a
-- property in several calls gives key-frames — played one after another
-- within the animation — just like repeating it in a single CLI command.

local colors = require("colors")

sbar.add("event", "lock", "com.apple.screenIsLocked")
sbar.add("event", "unlock", "com.apple.screenIsUnlocked")

local animator = sbar.add("item", {
  drawing = false,
  updates = true,
})

animator:subscribe("lock", function(env)
  sbar.bar({
    y_offset = -40,
    margin = -200,
    color = colors.transparent,
  })
end)

animator:subscribe("unlock", function(env)
  sbar.animate("sin", 25, function()
    -- Slides down and in from the edges with rounded corners, and only then
    -- squares off and fades to the bar colour.
    sbar.bar({
      y_offset = 0,
      margin = 0,
      corner_radius = 20,
      color = colors.transparent,
    })
    sbar.bar({ corner_radius = 20, color = colors.transparent })
    sbar.bar({ corner_radius = 20, color = colors.bar.bg })
    sbar.bar({ corner_radius = 0 })
  end)
end)
