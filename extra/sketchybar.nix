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

{ pkgs, ... }: {
  # Nerd Font glyphs for the bar's icons/labels, plus SketchyBar's own
  # per-app icon font. System-wide via /Library/Fonts (nix-darwin's
  # fonts.packages) rather than HM — macOS discovers fonts by scanning
  # ~/Library/Fonts or /Library/Fonts, not via fontconfig, and HM has no
  # Darwin font-install option.
  fonts.packages = [
    pkgs.nerd-fonts.hack
    pkgs.sketchybar-app-font
  ];

  home-manager.users.${username} = { pkgs, ... }: {
    home.packages = [ pkgs.sketchybar ];

    # Minimal starter bar: front-most app on the left, clock on the right.
    # Extend from here — https://felixkratz.github.io/SketchyBar/config.
    # SketchyBar execs this file directly, so it must be executable.
    xdg.configFile."sketchybar/sketchybarrc" = {
      executable = true;
      text = ''
        #!/bin/bash

        PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

        sketchybar --bar \
            height=32 \
            position=top \
            padding_left=10 \
            padding_right=10 \
            color=0xff1e1e2e

        sketchybar --default \
            icon.font="Hack Nerd Font:Bold:14.0" \
            icon.color=0xffffffff \
            label.font="Hack Nerd Font:Bold:14.0" \
            label.color=0xffffffff \
            padding_left=5 \
            padding_right=5

        sketchybar --add item front_app left \
            --set front_app \
                icon.drawing=off \
                script="$PLUGIN_DIR/front_app.sh" \
            --subscribe front_app front_app_switched

        sketchybar --add item clock right \
            --set clock \
                icon.drawing=off \
                update_freq=10 \
                script="$PLUGIN_DIR/clock.sh"

        sketchybar --update
      '';
    };

    xdg.configFile."sketchybar/plugins/front_app.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        sketchybar --set "$NAME" label="$INFO"
      '';
    };

    xdg.configFile."sketchybar/plugins/clock.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        sketchybar --set "$NAME" label="$(date '+%a %d %b  %H:%M')"
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
}
