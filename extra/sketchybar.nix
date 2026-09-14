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

  home-manager.users.${username} = { pkgs, ... }:
    let
      # launchd user agents run with macOS's minimal default PATH
      # (/usr/bin:/bin:/usr/sbin:/sbin), which doesn't include the Nix
      # profile — so both sketchybarrc and the plugin scripts it points at
      # must call sketchybar by absolute store path, not rely on PATH.
      sketchybarBin = "${pkgs.sketchybar}/bin/sketchybar";
    in {
    home.packages = [ pkgs.sketchybar ];

    # Minimal starter bar: front-most app on the left, clock on the right.
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

        ${sketchybarBin} --add item calendar right \
            --set calendar \
                icon= \
                click_script="$PLUGIN_DIR/open_calendar.sh" \
                update_freq=3600 \
                script="$PLUGIN_DIR/calendar.sh" \
            --subscribe calendar system_woke

        ${sketchybarBin} --add item clock right \
            --set clock \
                icon.drawing=off \
                update_freq=10 \
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
        ${sketchybarBin} --set "$NAME" label="$(date '+%a %d %b  %H:%M')"
      '';
    };

    # Mimics Fantastical's own menu-bar icon: a calendar glyph with today's
    # day-of-month as the label. Click opens Fantastical's Mini Window (see
    # open_calendar.sh below) for the popover Fantastical's own menu-bar
    # icon would normally show.
    xdg.configFile."sketchybar/plugins/calendar.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set "$NAME" label="$(date '+%e' | tr -d ' ')"
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
}
