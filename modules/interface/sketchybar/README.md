# SketchyBar config

SketchyBar ([GitHub](https://github.com/FelixKratz/SketchyBar) [Docs](https://felixkratz.github.io/SketchyBar/)) is a tool for creating full customiseable menu bars.

My config is based on [FelixKratz's config](https://github.com/FelixKratz/dotfiles/tree/master/.config/sketchybar) (SketchyBar creator), using the [SbarLua](https://github.com/FelixKratz/SbarLua) plugin to write components in Lua as opposed to shell script.

Useful links:
- [awesome-sketchybar](https://github.com/nicolas-martin/awesome-sketchybar/tree/master#Cpu)
- [Share your plugins](https://github.com/FelixKratz/SketchyBar/discussions/12?sort=top)
- [Share your setups](https://github.com/FelixKratz/SketchyBar/discussions/47?sort=top)

FelixKratz features:
- Date/time
- Battery
- Volume
- WiFi
- CPU monitor
- Current app menus
- Spaces

Modifications from FelixKratz's setup:
- Fix WiFi SSID command
- Open Fantastical mini-window when clicking date/tiem
- Add open WiFi settings button to WiFi popup
- The WiFi icon becomes a hotspot icon while connected to a hotspot — any network macOS flags as expensive, i.e. iPhone Personal Hotspot and metered Android hotspots (`config/helpers/event_providers/network_path/`)
- The workspaces/menus switch (and ⌥`) cycles workspaces → app menus → native macOS bar; an eye-with-a-slash icon in the native bar (or ⌥` again) returns to SketchyBar
- Spaces show AeroSpace workspaces (focused + non-empty ones) instead of native macOS Spaces; click one to switch to it
- Spaces' app icons use the icon map shipped with `sketchybar-app-font` (so every app the font knows gets its icon); point an app at a different glyph in the `overrides` table in `config/helpers/app_icons.lua`
- Custom app icons built into the font from `app-font/` (currently GitButler): add `svgs/:name:.svg` (24×24, solid shapes) and `mappings/:name:` (the app names, e.g. `"GitButler"`)
- Safari button (between Spotify and the widgets) for the current workspace's profile: coloured by the profile, it focuses that profile's open Safari window or opens a new one (Personal on workspaces without a profile) — `config/items/safari.lua`
- Red "SERVICE" pill with the key hints while AeroSpace is in service mode, and a blue ⌥ pill with the main-mode hints while Option is held (`option-hint.c` watches the key)
- Lock/unlock animation ([Source](https://github.com/nicolas-martin/awesome-sketchybar/blob/master/plugins/Simple-LockUnlock-Animation.md))
- Replace media with Spotify-specific setup, because macOS removed their private media API

## Source patch

We apply a local patch (`modules/interface/sketchybar/layered-window-levels.patch`) that stops the bar dimming after a click on empty bar space

## Re-signing

We resign the installed app, with a stable identity from agenix (`modules/interface/signing.nix`, shared with aerospace-swipe), so that accessibility grants stay between updates.

Re-signed copy lives at `~/.local/libexec/sketchybar/sketchybar`

If you add a grant, you might need to run
```shell
launchctl kickstart -k gui/$(id -u)/org.nixos.sketchybar
```
