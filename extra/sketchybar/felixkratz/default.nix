# FelixKratz's own SketchyBar config (the SketchyBar author), in Lua via
# SbarLua. ./config is a copy of .config/sketchybar from
# github.com/FelixKratz/dotfiles @ 67ad686 (2025-10-04), GPL-3.0 (./LICENSE).
# Edit it in place; to re-sync with upstream, copy the directory over again
# and re-apply the local tweaks (carried over from ../classic):
#   - items/calendar.lua: click opens Fantastical's Mini Window, not Calendar
#   - items/widgets/wifi.lua: SSID read from the preferred-networks list, as
#     ipconfig's is redacted without Location Services; plus an "Open Wi-Fi
#     Settings" row at the bottom of its popup
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
# Returns the finished config directory; ../default.nix links it to
# ~/.config/sketchybar.
{ pkgs }:

let
  lua = pkgs.lua5_5;
in
pkgs.stdenv.mkDerivation {
  pname = "sketchybar-config-felixkratz";
  version = "0-unstable-2025-10-04";
  src = ./config;

  postPatch = ''
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
    runHook postInstall
  '';
}
