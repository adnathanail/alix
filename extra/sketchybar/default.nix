# SketchyBar — menu-bar replacement. https://felixkratz.github.io/SketchyBar/setup
#
# The binary + fonts are Nix packages; the config lives under
# ~/.config/sketchybar (HM-owned, like the Ghostty config). Autostart is a
# system-level launchd user agent — Home Manager on Darwin has no
# `launchd.agents` option, so this is the Nix equivalent of
# `brew services start sketchybar`.
#
# Two interchangeable bar configs, each a directory derivation that becomes
# ~/.config/sketchybar — pick one with `barConfig` below:
#   ./felixkratz — FelixKratz's own Lua config, vendored (active)
#   ./classic    — the original hand-rolled bash widgets (disconnected)
# Everything else here (fonts, launchd, signing, restart-on-rebuild) is
# shared by both.
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
  age.secrets.sketchybar-signing-identity = {
    file = ../../secrets/sketchybar-signing-identity.age;
    owner = username;
    mode = "0400";
  };

  # Nerd Font glyphs for ./classic's icons/labels, plus SketchyBar's own
  # per-app icon font (./felixkratz's spaces). System-wide via /Library/Fonts (nix-darwin's
  # fonts.packages) rather than HM — macOS discovers fonts by scanning
  # ~/Library/Fonts or /Library/Fonts, not via fontconfig, and HM has no
  # Darwin font-install option.
  fonts.packages = [
    pkgs.nerd-fonts.hack
    pkgs.sketchybar-app-font
  ];

  # SF Pro / SF Mono are ./felixkratz's text and number fonts (its
  # settings.lua), and SF Pro also carries the SF Symbols glyphs its icons.lua
  # uses. Apple doesn't license them for redistribution, so nixpkgs has no
  # package; the casks install Apple's own .pkg.
  homebrew.casks = [ "font-sf-pro" "font-sf-mono" ];

  home-manager.users.${username} = { pkgs, lib, ... }:
    let
      # launchd user agents run with macOS's minimal default PATH
      # (/usr/bin:/bin:/usr/sbin:/sbin), which doesn't include the Nix
      # profile — so the classic bar calls sketchybar by absolute store
      # path rather than relying on PATH.
      sketchybarBin = "${pkgs.sketchybar}/bin/sketchybar";

      barConfig = import ./felixkratz { inherit pkgs; };
      # barConfig = import ./classic { inherit pkgs lib sketchybarBin; };
    in {
      home.packages = [ pkgs.sketchybar ];

      # recursive: per-file links inside a real directory rather than one
      # directory symlink, so HM never has to replace the existing
      # ~/.config/sketchybar directory (a collision) when switching configs.
      xdg.configFile."sketchybar" = {
        source = barConfig;
        recursive = true;
      };
    };

  # Autostart, equivalent to `brew services start sketchybar`.
  launchd.user.agents.sketchybar = {
    serviceConfig = {
      ProgramArguments = [ signedBin ];
      # ./felixkratz shells out to bare command names (`sketchybar --set` in
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
  # the files it points at change. Without this, every sketchybarrc/plugin
  # edit would silently sit unapplied until something manually restarted
  # the process. `kickstart -k` kills and relaunches it in one step, same
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
