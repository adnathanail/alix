# ExtraDock 5 — not yet packaged by the Homebrew cask (which tracks the v4
# releases repo, AppitStudio/extra-dock-updates). v5 ships from a separate
# "extra-dock5-updates" repo via a mutable "prod" release tag, so the dmg at
# this URL can change without the URL changing — bump `version` and refetch
# the hash (`nix-prefetch-url --type sha256 <url>`) whenever AppitStudio
# ships an update; a stale hash just fails the build loudly, it won't
# silently serve old bits.
{ pkgs, lib, ... }:
let
  version = "5.0.7";
  extradock = pkgs.stdenvNoCC.mkDerivation {
    pname = "extradock";
    inherit version;
    src = pkgs.fetchurl {
      name = "ExtraDock-${version}.dmg";
      url = "https://github.com/AppitStudio/extra-dock5-updates/releases/download/prod/ExtraDock.dmg";
      hash = "sha256-Onckd9eVIACa+ZIRoj1I9aR6gc9WRfFXpinf6oA3J4c=";
    };
    nativeBuildInputs = [ pkgs.undmg ];
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      cp -R ExtraDock.app $out/Applications/
      runHook postInstall
    '';
    meta = {
      description = "Fully customizable extra docks (v5 beta channel)";
      homepage = "https://extradock.app/";
      platforms = lib.platforms.darwin;
    };
  };
in {
  home.packages = [ extradock ];
}
