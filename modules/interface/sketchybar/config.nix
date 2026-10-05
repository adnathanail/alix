# The bar config: FelixKratz's own (the SketchyBar author), in Lua via
# SbarLua. ./config is a copy of .config/sketchybar from
# github.com/FelixKratz/dotfiles @ 67ad686 (2025-10-04), GPL-3.0 (./LICENSE).
# Edit it in place; to re-sync with upstream, copy the directory over again
# and re-apply the local tweaks:
#   - items/calendar.lua: click opens Fantastical's Mini Window, not Calendar
#   - items/widgets/wifi.lua: SSID read from the preferred-networks list, as
#     ipconfig's is redacted without Location Services; plus an "Open Wi-Fi
#     Settings" row at the bottom of its popup
#   - items/menubar.lua (+ its require in items/init.lua): new, the
#     `bar_cycle` event — workspaces → app menus → native macOS menu bar —
#     that the switch and front_app clicks now trigger instead of
#     swap_menus_and_spaces, plus the `menubar_hide` event that
#     ../menubar-return.m triggers
#   - bar.lua: `topmost = "on"`; colors.lua: bar background fully opaque —
#     together these draw the bar over the (never-hidden) native menu bar
#   - items/lock_animation.lua (+ its require): new, animates the bar back in
#     after unlocking the screen
#   - items/spotify.lua (upstream's items/media.lua, renamed): Spotify-only,
#     driven by Spotify's own notification + AppleScript instead of
#     SketchyBar's dead media_change event; covers shrunk to 28pt
#   - items/spaces.lua: AeroSpace workspaces instead of native Spaces/yabai;
#     it now shows/hides its own items on swap_menus_and_spaces (menus.lua
#     no longer sets them)
#   - helpers/app_icons.lua: replaced — loads the icon map that ships with
#     sketchybar-app-font (substituted in below) plus a local overrides
#     table, instead of upstream's hand-copied snapshot
#   - profiles.lua: new, generated below from ../profiles.nix
#   - items/safari.lua (+ its require): new, a Safari button for the focused
#     workspace's profile; focuses/opens windows with ../safari-window.nix
#   - items/aerospace_mode.lua (+ its require): new, AeroSpace key-hint
#     pills — one in service mode, one while Option is held
#   - items/notifications.lua (+ its require): new, Slack/MailMate icons
#     and unread count, pushed in by Hammerspoon
#
# Upstream assumes a mutable ~/.config/sketchybar, which the store isn't, so
# this derivation fixes up the three places that break:
#   - sketchybarrc's `#!/usr/bin/env lua` — launchd's PATH has no lua, and
#     it must be the Lua SbarLua was built against: nixpkgs' `sbarlua` is a
#     lua55Packages build, while plain `pkgs.lua` is still 5.2.
#   - helpers/init.lua points package.cpath at ~/.local/share/sketchybar_lua
#     (where SbarLua's install script puts it) → the store's sbarlua instead.
#   - helpers/init.lua runs `make` in the config dir on every startup, which
#     can't write to the store → the helpers are built here, once, instead.
#     The binaries land at the same helpers/**/bin/ paths the Lua expects.
#
# --replace-fail makes a re-sync that moves any of these lines fail the build
# rather than silently leaving the upstream behaviour in.
#
# Returns the finished config directory; ./default.nix links it to
# ~/.config/sketchybar.
{ pkgs }:

let
  inherit (pkgs) lib;
  lua = pkgs.lua5_5;

  # The profiles (../profiles.nix) as profiles.lua, keyed by workspace:
  #   return { ["4"] = { name = "Fermioniq", colour = 0xffee8076 }, … }
  # for items/spaces.lua's pill colours. "#rrggbb" becomes SketchyBar's
  # 0xAARRGGBB, fully opaque.
  argb = colour:
    let hex = lib.removePrefix "#" colour; in
    assert lib.assertMsg (builtins.match "[0-9a-fA-F]{6}" hex != null)
      "profiles.nix: colour must be \"#rrggbb\", got \"${colour}\"";
    "0xff${hex}";
  profilesLua = pkgs.writeText "profiles.lua" ''
    -- Generated from modules/interface/profiles.nix by ../config.nix.
    return {
    ${lib.concatMapStrings (p: ''
      ["${toString p.workspace}"] = { name = "${p.name}", colour = ${argb p.colour} },
    '') (import ../profiles.nix)}}
  '';
in
pkgs.stdenv.mkDerivation {
  pname = "sketchybar-config";
  version = "0-unstable-2025-10-04";
  src = ./config;

  postPatch = ''
    substituteInPlace items/safari.lua \
      --replace-fail '@safariWindow@' '${import ../safari-window.nix { inherit pkgs; }}'
    substituteInPlace helpers/app_icons.lua \
      --replace-fail '@iconMap@' '${pkgs.sketchybar-app-font}/lib/sketchybar-app-font/icon_map.lua'
    substituteInPlace sketchybarrc \
      --replace-fail '#!/usr/bin/env lua' '#!${lua}/bin/lua'
    substituteInPlace helpers/init.lua \
      --replace-fail '";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"' \
                     '";${pkgs.sbarlua}/lib/lua/${lua.luaversion}/?.so"' \
      --replace-fail 'os.execute("(cd helpers && make)")' ""
  '';

  # Upstream's own makefiles. menus links the private SkyLight framework
  # straight from /System/Library/PrivateFrameworks — fine because Lix's
  # Darwin builds aren't sandboxed.
  buildPhase = ''
    runHook preBuild
    make -C helpers
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -R . $out
    cp ${profilesLua} $out/profiles.lua
    runHook postInstall
  '';
}
