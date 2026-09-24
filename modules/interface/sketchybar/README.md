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
- Add button to swap sketchybar for macOS bar and back
- Start showing the current app's menus instead of the spaces (the switch icon next to them still toggles)
- Lock/unlock animation ([Source](https://github.com/nicolas-martin/awesome-sketchybar/blob/master/plugins/Simple-LockUnlock-Animation.md))
- Replace media with Spotify-specific setup, because macOS removed their private media API

## Source patch

We apply a local patch (`modules/interface/sketchybar/layered-window-levels.patch`) that stops the bar dimming after a click on empty bar space

## Re-signing

We resign the installed app, with a stable identity from agenix (`modules/interface/sketchybar/signing.nix`), so that accessibility grants stay between updates.

Re-signed copy lives at `~/.local/libexec/sketchybar/sketchybar`

If you add a grant, you might need to run
```shell
launchctl kickstart -k gui/$(id -u)/org.nixos.sketchybar
```
