# Rex Beta — preview build, not in Homebrew or nixpkgs. The download location
# isn't public, so it lives in nix-private (rex/base-url, see `privateDir` in
# flake.nix) and this module pins only the DMG's name and hash. Nix can't read
# that file during a pure build, so `requireFile` expects the DMG to be in the
# store already, and fails with the command that puts it there. That can come
# up again after a garbage collection, if something forces a rebuild.
#
# <base-url>/appcast.xml is the app's Sparkle feed, listing one
# `Rex-<version>-<build>.dmg` per build. Bump `version`, `build` and `hash`
# together (`nix hash file --sri --type sha256 <dmg>`).
#
# The feed only keeps recent builds. If this one has gone, a copy of the same
# DMG can be added directly, as long as it's named to match:
#     nix-store --add-fixed sha256 Rex-<version>-<build>.dmg
#
# Copied straight off a live `hdiutil` mount, for the same reason as ExtraDock
# (see ../interface/extradock.nix): it bundles Sparkle, whose nested signatures
# an archive-extraction tool would invalidate.
#
# Consumed from modules/apps/default.nix as:
#     ./rex.nix
{ username, privateDir, pkgs, lib, ... }:
let
  version = "0.1.0";
  build = "1829";
  dmg = "Rex-${version}-${build}.dmg";
  rex = pkgs.stdenvNoCC.mkDerivation {
    pname = "rex-beta";
    version = "${version}-${build}";
    src = pkgs.requireFile {
      name = dmg;
      hash = "sha256-+LAJifflXE36y8Go5Xa/RIgEmEkceSTMnIShPKrbv0k=";
      message = ''
        ${dmg} isn't in the Nix store. Add it, then rebuild:
          nix-prefetch-url --name ${dmg} "$(cat ${privateDir}/rex/base-url)/${dmg}"
      '';
    };
    dontUnpack = true;
    # The signed app ships a dangling Sparkle.framework/XPCServices symlink,
    # and removing it would break the signature.
    dontCheckForBrokenSymlinks = true;
    installPhase = ''
      runHook preInstall
      mnt=$(mktemp -d)
      /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$src"
      mkdir -p $out/Applications
      cp -R "$mnt/Rex Beta.app" $out/Applications/
      /usr/bin/hdiutil detach "$mnt"
      runHook postInstall
    '';
    meta = {
      description = "Rex (preview channel)";
      platforms = lib.platforms.darwin;
    };
  };
in {
  home-manager.users.${username}.home.packages = [ rex ];

  # The store copy is read-only, so Sparkle can't update it; stop it checking.
  system.defaults.CustomUserPreferences."com.superlogical.rex".SUEnableAutomaticChecks = false;
}
