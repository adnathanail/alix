local colors = require("colors")
local settings = require("settings")

-- A key-hint pill: a bold tag (e.g. "SERVICE") and a line of hints, black on
-- a coloured background. Starts hidden; the caller shows it with
-- `pill:set({ drawing = … })` from its own event handlers.
--
-- opts:
--   tag           the bold text on the left
--   hints         the hint line
--   color         background colour
--   icon_size     tag font size (default 12; larger suits a lone glyph)
--   padding_left, padding_right   space outside the pill, on either side
return function(name, opts)
  return sbar.add("item", name, {
    drawing = false,
    -- Hidden items skip their event handlers by default, which would leave
    -- the pill unable to show itself.
    updates = true,
    icon = {
      string = opts.tag,
      color = colors.black,
      font = {
        style = settings.font.style_map["Heavy"],
        size = opts.icon_size or 12.0,
      },
      padding_left = 10,
      padding_right = 6,
    },
    label = {
      string = opts.hints,
      color = colors.black,
      font = { style = settings.font.style_map["Semibold"], size = 12.0 },
      padding_right = 10,
    },
    background = {
      color = opts.color,
      border_color = colors.black,
      border_width = 1,
      height = 26,
    },
    padding_left = opts.padding_left,
    padding_right = opts.padding_right,
  })
end
