# SketchyBar — menu-bar replacement. https://felixkratz.github.io/SketchyBar/setup
#
# The binary + fonts are Nix packages; the config lives under
# ~/.config/sketchybar (HM-owned, like the Ghostty config). Autostart is a
# system-level launchd user agent — Home Manager on Darwin has no
# `launchd.agents` option, so this is the Nix equivalent of
# `brew services start sketchybar`.
#
# Consumed from flake.nix as:
#     (import ./extra/sketchybar.nix { inherit username; })
{ username }:

# To check
# - https://github.com/FelixKratz/SketchyBar/discussions/281
# - https://github.com/FelixKratz/SketchyBar/discussions/229

{ lib, pkgs, ... }: {
  # Nerd Font glyphs for the bar's icons/labels, plus SketchyBar's own
  # per-app icon font. System-wide via /Library/Fonts (nix-darwin's
  # fonts.packages) rather than HM — macOS discovers fonts by scanning
  # ~/Library/Fonts or /Library/Fonts, not via fontconfig, and HM has no
  # Darwin font-install option.
  fonts.packages = [
    pkgs.nerd-fonts.hack
    pkgs.sketchybar-app-font
  ];

  home-manager.users.${username} = { pkgs, ... }:
    let
      # launchd user agents run with macOS's minimal default PATH
      # (/usr/bin:/bin:/usr/sbin:/sbin), which doesn't include the Nix
      # profile — so both sketchybarrc and the plugin scripts it points at
      # must call sketchybar by absolute store path, not rely on PATH.
      sketchybarBin = "${pkgs.sketchybar}/bin/sketchybar";
    in {
    home.packages = [ pkgs.sketchybar ];

    # Bar: front-most app on the left; Fantastical's real menu-bar icon
    # (aliased in from the native menu bar) then the clock on the right.
    # Extend from here — https://felixkratz.github.io/SketchyBar/config.
    # SketchyBar execs this file directly, so it must be executable.
    xdg.configFile."sketchybar/sketchybarrc" = {
      executable = true;
      text = ''
        #!/bin/bash

        PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

        ${sketchybarBin} --bar \
            height=32 \
            position=top \
            padding_left=10 \
            padding_right=10 \
            color=0xff1e1e2e

        ${sketchybarBin} --default \
            icon.font="Hack Nerd Font:Bold:14.0" \
            icon.color=0xffffffff \
            label.font="Hack Nerd Font:Bold:14.0" \
            label.color=0xffffffff \
            padding_left=5 \
            padding_right=5

        ${sketchybarBin} --add item front_app left \
            --set front_app \
                icon.drawing=off \
                script="$PLUGIN_DIR/front_app.sh" \
            --subscribe front_app front_app_switched

        # Mirrors Fantastical's actual native menu-bar icon (requires
        # Screen Recording permission for sketchybar — see README). Click
        # opens Fantastical's Mini Window (see open_calendar.sh below)
        # rather than the full app.
        ${sketchybarBin} --add alias "Control Centre,Fantastical" right \
            --set "Control Centre,Fantastical" \
                alias.update_freq=60 \
                click_script="$PLUGIN_DIR/open_calendar.sh"

        ${sketchybarBin} --add item clock right \
            --set clock \
                icon.drawing=off \
                update_freq=1 \
                script="$PLUGIN_DIR/clock.sh"

        ${sketchybarBin} --update
      '';
    };

    xdg.configFile."sketchybar/plugins/front_app.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set "$NAME" label="$INFO"
      '';
    };

    xdg.configFile."sketchybar/plugins/clock.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set "$NAME" label="$(date '+%H:%M:%S')"
      '';
    };

    # Fantastical has no URL scheme or AppleScript command for its Mini
    # Window (the menu-bar popover) — it only opens via a system-wide
    # keyboard shortcut (Fantastical → Settings → General). This simulates
    # that shortcut (default Control+Option+Space, key code 49 = space)
    # through System Events instead of launching the full app. First click
    # will likely prompt for Accessibility permission, same as Rectangle/
    # Raycast — see README's manual-setup section.
    xdg.configFile."sketchybar/plugins/open_calendar.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        osascript -e 'tell application "System Events" to key code 49 using {control down, option down}'
      '';
    };
  };

  # Autostart, equivalent to `brew services start sketchybar`.
  launchd.user.agents.sketchybar = {
    serviceConfig = {
      ProgramArguments = [ "${pkgs.sketchybar}/bin/sketchybar" ];
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
  system.activationScripts.postActivation.text = lib.mkAfter ''
    launchctl asuser "$(id -u -- ${username})" \
      sudo --user=${username} -- \
      launchctl kickstart -k "gui/$(id -u -- ${username})/org.nixos.sketchybar" \
      2>/dev/null || true
  '';
}
