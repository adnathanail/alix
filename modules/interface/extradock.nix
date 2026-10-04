# ExtraDock 5 — not yet packaged by the Homebrew cask (which tracks the v4
# releases repo, AppitStudio/extra-dock-updates). v5 ships from a separate
# "extra-dock5-updates" repo, one release tag per version (`v<version>`,
# plus a mutable "prod" tag pointing at the latest). The URL uses the
# versioned tag so the pin stays put — bump `version` and refetch the hash
# (`nix-prefetch-url --type sha256 <url>`) together.
#
# Must unpack via `hdiutil attach` + `cp`, not `undmg`/`7zz`: this app
# bundles Sparkle's signed XPC helpers, and macOS stamps a fresh
# `com.apple.provenance` xattr on any executable materialized by an
# archive-extraction tool, which invalidates their nested code signatures
# (`codesign --verify --deep --strict` then fails with "a sealed resource
# is missing or invalid", and Gatekeeper refuses to launch it). Copying
# from a live dmg mount doesn't trigger this. `hdiutil` isn't on the
# sandboxed build's PATH, hence the absolute `/usr/bin/hdiutil`.
{ pkgs, lib, ... }:
let
  version = "5.1.0";
  extradock = pkgs.stdenvNoCC.mkDerivation {
    pname = "extradock";
    inherit version;
    src = pkgs.fetchurl {
      name = "ExtraDock-${version}.dmg";
      url = "https://github.com/AppitStudio/extra-dock5-updates/releases/download/v${version}/ExtraDock.dmg";
      hash = "sha256-AY872yPpFjwfhIoM4QbjuZaewlHeNX4/6r3VhWcnvh4=";
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mnt=$(mktemp -d)
      /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$src"
      mkdir -p $out/Applications
      cp -R "$mnt/ExtraDock.app" $out/Applications/
      /usr/bin/hdiutil detach "$mnt"
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
  # extradock-config.nix runs the bundled MCP helper from it.
  _module.args.extradock = extradock;
}
