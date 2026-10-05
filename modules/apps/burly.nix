# Burly — menu-bar link router: pick a browser profile for each link
# clicked in another app. Not in Homebrew or nixpkgs; ships as a notarized
# DMG. Its Sparkle appcast lists one versioned URL per release
# (`releases/v<version>/Burly-<version>.dmg`; the website's
# `/download/Burly.dmg` redirects to a mutable `releases/latest/`), so the
# pin uses the versioned one — bump `version` and refetch the hash
# (`nix-prefetch-url --type sha256 <url>`) together.
#
# Unpacked via `hdiutil attach` + `cp`, not `undmg`, for the same reason as
# ExtraDock (see ../interface/extradock.nix): it bundles Sparkle, whose
# nested signatures an archive-extraction tool would invalidate.
{ pkgs, lib, ... }:
let
  version = "1.4.0";
  burly = pkgs.stdenvNoCC.mkDerivation {
    pname = "burly";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/burly-prod.firebasestorage.app/releases/v${version}/Burly-${version}.dmg";
      hash = "sha256-vieCMH10LYsD2d2QnaduT4G/t+kBeCyQOd5vBz8mreQ=";
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mnt=$(mktemp -d)
      /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$src"
      mkdir -p $out/Applications
      cp -R "$mnt/Burly.app" $out/Applications/
      /usr/bin/hdiutil detach "$mnt"
      runHook postInstall
    '';
    meta = {
      description = "Browser profile picker and link router";
      homepage = "https://www.burly.click/";
      platforms = lib.platforms.darwin;
    };
  };
in {
  home.packages = [ burly ];

  # The store copy is read-only, so Sparkle can't update it; stop it checking.
  targets.darwin.defaults."com.mattsenter.Burly".SUEnableAutomaticChecks = false;
}
