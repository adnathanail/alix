# SketchyBar — menu-bar replacement. https://felixkratz.github.io/SketchyBar/setup
#
# The binary + fonts are Nix packages; the config lives under
# ~/.config/sketchybar (HM-owned, like the Ghostty config). Autostart is a
# system-level launchd user agent — Home Manager on Darwin has no
# `launchd.agents` option, so this is the Nix equivalent of
# `brew services start sketchybar`.
#
# The bar itself is FelixKratz's Lua config, vendored under ./config and
# built by ./config.nix. This file owns everything around it: fonts, the
# launchd agent, signing, and restart-on-rebuild.
#
# The launchd-run server is a re-signed copy at a fixed path, not the store
# binary, so privacy grants given to SketchyBar survive updates. See
# ./signing.nix.
#
# Consumed from flake.nix as:
#     (import ./extra/sketchybar { inherit username; })
{ username }:

{ lib, pkgs, ... }:
let
  # The server binary launchd runs: a stable-path, stably-signed copy of
  # pkgs.sketchybar (./signing.nix). This path is what privacy grants are
  # given to, so don't move it.
  signedBin = "/Users/${username}/.local/libexec/sketchybar/sketchybar";
  signSketchybar = import ./signing.nix { inherit pkgs; };
in {
  # Local patch: put the bar background, brackets and items on three
  # separate window levels. Upstream shares one, and macOS raises a clicked
  # window above its same-level siblings, so clicking empty bar space lifted
  # the background over every item and dimmed the whole bar until SketchyBar
  # restarted (see the patch for details). mkAfter so it applies on top of
  # flake.nix's unstableOverlay, which is what swaps in 2.24 — otherwise the
  # overlay would replace the patched package with the plain unstable one.
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      sketchybar = prev.sketchybar.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./layered-window-levels.patch ];
      });
    })
  ];

  age.secrets.sketchybar-signing-identity = {
    file = ../../secrets/sketchybar-signing-identity.age;
    owner = username;
    mode = "0400";
  };

  # SketchyBar's own per-app icon font, for the spaces' app icons.
  # System-wide via /Library/Fonts (nix-darwin's fonts.packages) rather than
  # HM — macOS discovers fonts by scanning ~/Library/Fonts or /Library/Fonts,
  # not via fontconfig, and HM has no Darwin font-install option.
  fonts.packages = [ pkgs.sketchybar-app-font ];

  # SF Pro / SF Mono are the config's text and number fonts (its
  # settings.lua), and SF Pro also carries the SF Symbols glyphs its icons.lua
  # uses. Apple doesn't license them for redistribution, so nixpkgs has no
  # package; the casks install Apple's own .pkg.
  homebrew.casks = [ "font-sf-pro" "font-sf-mono" ];

  home-manager.users.${username} = { pkgs, ... }: {
    home.packages = [ pkgs.sketchybar ];

    # recursive: per-file links inside a real directory rather than one
    # directory symlink, so HM never has to replace an existing
    # ~/.config/sketchybar directory (a collision).
    xdg.configFile."sketchybar" = {
      source = import ./config.nix { inherit pkgs; };
      recursive = true;
    };
  };

  # Autostart, equivalent to `brew services start sketchybar`.
  launchd.user.agents.sketchybar = {
    serviceConfig = {
      ProgramArguments = [ signedBin ];
      # launchd user agents get macOS's minimal default PATH, and the config
      # shells out to bare command names (`sketchybar --set` in
      # click scripts, SwitchAudioSource for the volume popup's device list,
      # nowplaying-cli for the media widget's buttons), so those go on the
      # server's PATH, ahead of launchd's default. Its spaces widget also
      # calls `yabai` on click, which isn't installed — clicking a space
      # does nothing.
      EnvironmentVariables.PATH = lib.concatStringsSep ":" [
        (lib.makeBinPath [ pkgs.sketchybar pkgs.switchaudio-osx pkgs.nowplaying-cli ])
        "/usr/bin:/bin:/usr/sbin:/sbin"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${username}/Library/Logs/sketchybar.log";
      StandardErrorPath = "/Users/${username}/Library/Logs/sketchybar.err.log";
    };
  };

  # SketchyBar only executes sketchybarrc once, at process startup — it
  # never re-sources it on its own. Activation updates the config files on
  # disk (xdg.configFile above) but nix-darwin only reloads a launchd job
  # when the *plist itself* changes, which it never does here since only
  # the files it points at change. Without this, every config edit would
  # silently sit unapplied until something manually restarted the process. `kickstart -k` kills and relaunches it in one step, same
  # pattern nix-darwin's own launchd.nix uses for userLaunchAgents.
  #
  # mkAfter matters here: Home Manager's own activation step (which is what
  # actually writes the new config file symlinks) is appended to this same
  # postActivation.text by home-manager.darwinModules.home-manager, later
  # in flake.nix's module list. Without mkAfter, plain module-order
  # concatenation puts our kickstart *before* that HM step, so it would
  # restart sketchybar with the previous rebuild's config, one step behind.
  #
  # Signing runs first, in the same block, so the kickstart always picks up
  # the freshly signed binary. It runs as the user (in their security
  # session, via the same asuser dance), so the throwaway keychain works and
  # the output is user-owned. A signing failure is reported but doesn't fail
  # activation; the previous signed copy keeps running.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    launchctl asuser "$(id -u -- ${username})" \
      sudo --user=${username} -- \
      ${signSketchybar} ${pkgs.sketchybar}/bin/sketchybar \
        /run/agenix/sketchybar-signing-identity ${signedBin} \
      || echo "sketchybar: signing failed; privacy grants may not apply" >&2
    launchctl asuser "$(id -u -- ${username})" \
      sudo --user=${username} -- \
      launchctl kickstart -k "gui/$(id -u -- ${username})/org.nixos.sketchybar" \
      2>/dev/null || true
  '';
}
