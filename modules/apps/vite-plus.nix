# Vite+ (`vp`, plus `vpr`/`vpx`) — VoidZero's unified web toolchain CLI.
# Not in nixpkgs. Homebrew's formula depends on Homebrew's node, which would
# land in /opt/homebrew/bin ahead of the Nix-managed node on PATH, so this
# packages the official prebuilt binary instead: the same npm platform
# tarball the vite.plus install script downloads. It's a single Rust
# executable linking only system frameworks, so it runs from the store as-is.
#
# To bump, change `version` and take the new `hash` from the tarball's npm
# integrity field:
#     curl -s https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-arm64/<version> | jq -r .dist.integrity
#
# On first run vp sets itself up under ~/.local/share/vite-plus (its own Node.js,
# package-manager shims and the vite-plus JS package). Its attempt to add
# ~/.config/vite-plus/env to the shell profile fails harmlessly against HM's
# read-only .zshrc; leave it that way so its node/pnpm shims don't shadow
# Nix's. Don't use `vp upgrade` — bump the pin here instead.
{ pkgs, lib, ... }:
let
  version = "1.1.0";
  vite-plus = pkgs.stdenvNoCC.mkDerivation {
    pname = "vite-plus";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-darwin-arm64/-/vite-plus-cli-darwin-arm64-${version}.tgz";
      hash = "sha512-PFpvpBUCqlvS1f2oCsNHnJSFHT7SOK/QeCJwhs/GLcvtOyyAY4tT6QmxyZzom4D33g63GfZ6y25e3yyFkchncg==";
    };
    installPhase = ''
      runHook preInstall
      install -Dm755 vp $out/bin/vp
      # vpr and vpx are vp itself, dispatched on argv[0].
      ln -s vp $out/bin/vpr
      ln -s vp $out/bin/vpx
      runHook postInstall
    '';
    meta = {
      description = "Unified toolchain and entry point for web development";
      homepage = "https://viteplus.dev";
      license = lib.licenses.mit;
      platforms = [ "aarch64-darwin" ];
      mainProgram = "vp";
    };
  };
in
{
  home.packages = [ vite-plus ];
}
