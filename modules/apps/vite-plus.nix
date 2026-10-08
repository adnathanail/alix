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
# On first run vp sets itself up under ~/.local/share/vite-plus: a copy of
# itself, the vite-plus JS package, and shims for node, npm, pnpm, yarn and
# bun. Its attempt to add ~/.config/vite-plus/env to the shell profile fails
# harmlessly against HM's read-only .zshrc.
#
# vp runs in system-first mode (`vp env off`, run once by hand — it's stored
# in ~/.config/vite-plus/config.json). Plain `node`/`npm`/`pnpm` stay Nix's
# everywhere; commands run through vp (`vp node`, `vp env exec`, `vp dev`, …)
# use the version the project asks for (package.json `devEngines`/`engines`,
# .node-version, .nvmrc, or `vp env pin`), downloaded on demand into vp's
# data dir, outside the store, much as uv manages Python. vp's default,
# managed mode (`vp env on`) would make the shims pick the project's version
# for plain `node` too, and vp's own default outside projects.
#
# PATH is set here rather than by sourcing vp's env script (which would also
# run `vp` on every shell start for completions). In system-first mode the
# node/npm/pnpm shims sit in fallback-bin, after Nix's tools; in managed mode
# they move to bin, ahead of them. bin also gets vp/vpr/vpx links to vp's
# self-managed copy, which would shadow this pinned one, so activation
# removes them. Don't use `vp upgrade` — bump the pin here instead.
{ config, pkgs, lib, ... }:
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

  # bin first and fallback-bin last, as in vp's own env script. In .zshrc
  # rather than home.sessionPath: /etc/zshrc and the login-shell files run
  # after .zshenv and prepend their own entries, which would put Nix's tools
  # back in front of bin. GUI apps that read the login shell's environment
  # (VS Code) pick this up too.
  programs.zsh.initContent = ''
    path=(
      "$HOME/.local/share/vite-plus/bin"
      ''${path:#$HOME/.local/share/vite-plus/(bin|fallback-bin)}
      "$HOME/.local/share/vite-plus/fallback-bin"
    )
  '';

  home.activation.vitePlusDropSelfManagedVp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for name in vp vpr vpx; do
      link="${config.home.homeDirectory}/.local/share/vite-plus/bin/$name"
      if [ -L "$link" ]; then
        run rm "$link"
      fi
    done
  '';
}
