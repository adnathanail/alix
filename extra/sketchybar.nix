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

        # Apple menu: a dropdown popup, mimicking the native Apple menu.
        # Sits left of front_app so the bar reads Apple icon then the app
        # name, same order as the real menu bar. SketchyBar has no built-in
        # way to detect a click outside the bar (unresolved upstream —
        # github.com/FelixKratz/SketchyBar/issues/655), so closing on an
        # outside click is wired up by hand from two directions: every
        # other bar item's click_script closes it explicitly (see
        # apple_menu_close.sh below), and front_app.sh closes it whenever
        # front_app_switched fires, which covers clicking away to the
        # desktop or another app. Icons are Nerd Font (Font Awesome 4)
        # glyphs, given as \u escapes rather than literal characters since
        # literal PUA glyphs don't survive round-tripping through some
        # editors.
        ${sketchybarBin} --add item apple_menu left \
            --set apple_menu \
                icon=$'' \
                icon.font="Hack Nerd Font:Bold:16.0" \
                label.drawing=off \
                click_script="$PLUGIN_DIR/apple_menu_toggle.sh" \
                popup.background.color=0xff1e1e2e \
                popup.background.border_color=0xff585b70 \
                popup.background.border_width=1 \
                popup.background.corner_radius=6 \
                popup.y_offset=5 \
            --add item apple_about popup.apple_menu \
            --set apple_about \
                icon=$'' \
                icon.padding_left=10 \
                icon.padding_right=8 \
                label="About This Mac" \
                label.align=left \
                width=160 \
                click_script="$PLUGIN_DIR/apple_about.sh" \
            --add item apple_settings popup.apple_menu \
            --set apple_settings \
                icon=$'' \
                icon.padding_left=10 \
                icon.padding_right=8 \
                label="System Settings" \
                label.align=left \
                width=160 \
                click_script="$PLUGIN_DIR/apple_settings.sh" \
            --add item apple_activity popup.apple_menu \
            --set apple_activity \
                icon=$'' \
                icon.padding_left=10 \
                icon.padding_right=8 \
                label="Activity Monitor" \
                label.align=left \
                width=160 \
                click_script="$PLUGIN_DIR/apple_activity.sh" \
            --add item apple_line popup.apple_menu \
            --set apple_line \
                icon.drawing=off \
                label.drawing=off \
                background.drawing=on \
                background.color=0xff585b70 \
                background.height=1 \
                height=8 \
                width=160 \
            --add item apple_logout popup.apple_menu \
            --set apple_logout \
                icon=$'' \
                icon.padding_left=10 \
                icon.padding_right=8 \
                label="Log Out" \
                label.align=left \
                width=160 \
                click_script="$PLUGIN_DIR/apple_logout.sh" \
            --add item apple_shutdown popup.apple_menu \
            --set apple_shutdown \
                icon=$'' \
                icon.padding_left=10 \
                icon.padding_right=8 \
                label="Shut Down" \
                label.align=left \
                width=160 \
                click_script="$PLUGIN_DIR/apple_shutdown.sh" \
            --add item apple_restart popup.apple_menu \
            --set apple_restart \
                icon=$'' \
                icon.padding_left=10 \
                icon.padding_right=8 \
                label="Restart" \
                label.align=left \
                width=160 \
                click_script="$PLUGIN_DIR/apple_restart.sh"

        ${sketchybarBin} --add item front_app left \
            --set front_app \
                icon.drawing=off \
                script="$PLUGIN_DIR/front_app.sh" \
                click_script="$PLUGIN_DIR/apple_menu_close.sh" \
            --subscribe front_app front_app_switched

        # Mirrors Fantastical's actual native menu-bar icon (requires
        # Screen Recording permission for sketchybar — see README). Click
        # opens Fantastical's Mini Window (see open_calendar.sh below)
        # rather than the full app.
        ${sketchybarBin} --add alias "Control Centre,Fantastical" right \
            --set "Control Centre,Fantastical" \
                alias.update_freq=60 \
                click_script="$PLUGIN_DIR/apple_menu_close.sh && $PLUGIN_DIR/open_calendar.sh"

        ${sketchybarBin} --add item clock right \
            --set clock \
                icon.drawing=off \
                update_freq=1 \
                script="$PLUGIN_DIR/clock.sh" \
                click_script="$PLUGIN_DIR/apple_menu_close.sh"

        ${sketchybarBin} --update
      '';
    };

    # Also closes the Apple menu popup: SketchyBar has no way to detect a
    # click outside the bar itself (an open, unresolved upstream request —
    # https://github.com/FelixKratz/SketchyBar/issues/655), so clicking the
    # desktop or another app can't be caught directly. front_app_switched
    # already fires whenever a different app becomes frontmost, which is
    # true for essentially every "click elsewhere on screen" case (clicking
    # another app, or empty desktop which activates Finder), so it doubles
    # as that signal for free.
    xdg.configFile."sketchybar/plugins/front_app.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set "$NAME" label="$INFO"
        ${sketchybarBin} --set apple_menu popup.drawing=off
      '';
    };

    # Apple menu: toggle shows/hides the popup; each action item closes the
    # popup before doing its thing so it doesn't linger over whatever opens
    # next (System Settings, the logout confirmation, ...).
    xdg.configFile."sketchybar/plugins/apple_menu_toggle.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set apple_menu popup.drawing=toggle
      '';
    };

    # Wired into every other clickable item's click_script so clicking
    # anywhere else on the bar dismisses the Apple menu popup.
    xdg.configFile."sketchybar/plugins/apple_menu_close.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set apple_menu popup.drawing=off
      '';
    };

    xdg.configFile."sketchybar/plugins/apple_about.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set apple_menu popup.drawing=off
        open "/System/Library/CoreServices/Applications/About This Mac.app"
      '';
    };

    xdg.configFile."sketchybar/plugins/apple_settings.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set apple_menu popup.drawing=off
        open -a "System Settings"
      '';
    };

    xdg.configFile."sketchybar/plugins/apple_activity.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set apple_menu popup.drawing=off
        open -a "Activity Monitor"
      '';
    };

    # "log out"/"shut down"/"restart" via System Events raise the same
    # confirmation dialog as picking them from the real Apple menu (not
    # suppressed), so they can't be triggered by accident.
    xdg.configFile."sketchybar/plugins/apple_logout.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set apple_menu popup.drawing=off
        osascript -e 'tell application "System Events" to log out'
      '';
    };

    xdg.configFile."sketchybar/plugins/apple_shutdown.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set apple_menu popup.drawing=off
        osascript -e 'tell application "System Events" to shut down'
      '';
    };

    xdg.configFile."sketchybar/plugins/apple_restart.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        ${sketchybarBin} --set apple_menu popup.drawing=off
        osascript -e 'tell application "System Events" to restart'
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
