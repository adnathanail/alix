# Search (https://searchbrowser.app) — a small WebKit browser by Office
# Commun. Its only Homebrew cask lives in a third-party tap
# (driceroland/tap), so it's packaged here from the versioned GitHub
# release DMG instead, the same way as ExtraDock: copied straight off a
# live `hdiutil` mount so the Developer ID signature stays intact. Bump
# `version` and refetch the hash (`nix-prefetch-url --type sha256 <url>`,
# then `nix hash to-sri --type sha256 <hash>`) together.
#
# Consumed from modules/apps/default.nix as:
#     ./search.nix
{ username, pkgs, lib, ... }:
let
  version = "1.0.6";
  search = pkgs.stdenvNoCC.mkDerivation {
    pname = "search-browser";
    inherit version;
    src = pkgs.fetchurl {
      name = "Search-${version}.dmg";
      url = "https://github.com/driceroland/Search/releases/download/v${version}/Search.dmg";
      hash = "sha256-x+xvHWx5Da8vGTvv+KFWc2Bw6QkQvbfIYcGs8tse+CA=";
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mnt=$(mktemp -d)
      /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$src"
      mkdir -p $out/Applications
      cp -R "$mnt/Search.app" $out/Applications/
      /usr/bin/hdiutil detach "$mnt"
      runHook postInstall
    '';
    meta = {
      description = "Fast, light WebKit browser for the Mac";
      homepage = "https://searchbrowser.app/";
      platforms = lib.platforms.darwin;
    };
  };
in {
  home-manager.users.${username}.home.packages = [ search ];

  # Settings › About › "Install updates on its own". With it off, Search
  # still checks its feed hourly and offers a newer build, but never swaps
  # one in by itself — versions move with `version` above.
  system.defaults.CustomUserPreferences."com.officecommun.search" = {
    "update.install" = false;
  };
}
