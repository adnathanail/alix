-- App name (as AeroSpace / macOS report it) → sketchybar-app-font glyph
-- name, e.g. ":ghostty:". The map ships with the font package itself
-- (lib/sketchybar-app-font/icon_map.lua), so it always matches the glyphs
-- the installed font has; ../../config.nix substitutes its path in.
local icons = dofile("@iconMap@")

-- Point an app at a different existing glyph. The value must be a glyph
-- name the font has: every name is listed in the icon map above, or browse
-- them at https://github.com/kvndrsslr/sketchybar-app-font. For a brand-new
-- icon, add an SVG under ../../app-font instead (see ../../default.nix).
local overrides = {
}

for app, glyph in pairs(overrides) do icons[app] = glyph end
return icons
