# SketchyBar — menu-bar replacement. https://felixkratz.github.io/SketchyBar/setup
#
# The binary + fonts are Nix packages; the config lives under
# ~/.config/sketchybar (HM-owned, like the Ghostty config). Autostart is a
# system-level launchd user agent — Home Manager on Darwin has no
# `launchd.agents` option, so this is the Nix equivalent of
# `brew services start sketchybar`.
#
# Each bar widget is its own file — apple-menu.nix, wifi.nix, clock.nix —
# returning `{ rc, plugins }`: `rc` is the sketchybarrc fragment that adds
# the widget's items, `plugins` is an attrset of plugin-script filename →
# contents. This file concatenates the rc fragments into one sketchybarrc
# (SketchyBar execs it once at startup, so it has to be a single script)
# and merges the plugin attrsets into xdg.configFile. front_app and
# close_popups.sh live here rather than in a widget file since they're
# cross-cutting — they reference both the Apple menu and WiFi popups by
# name.
#
# Consumed from flake.nix as:
#     (import ./extra/sketchybar { inherit username; })
{ username }:

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

  home-manager.users.${username} = { pkgs, lib, ... }:
    let
      # launchd user agents run with macOS's minimal default PATH
      # (/usr/bin:/bin:/usr/sbin:/sbin), which doesn't include the Nix
      # profile — so both sketchybarrc and the plugin scripts it points at
      # must call sketchybar by absolute store path, not rely on PATH.
      sketchybarBin = "${pkgs.sketchybar}/bin/sketchybar";

      appleMenu = import ./apple-menu.nix { inherit sketchybarBin; };
      wifi = import ./wifi.nix { inherit sketchybarBin; };
      clock = import ./clock.nix { inherit sketchybarBin; };

      widgetPlugins = appleMenu.plugins // wifi.plugins // clock.plugins // {
        # Also closes both popups (Apple menu, WiFi): SketchyBar has no way
        # to detect a click outside the bar itself (an open, unresolved
        # upstream request — github.com/FelixKratz/SketchyBar/issues/655),
        # so clicking the desktop or another app can't be caught directly.
        # front_app_switched already fires whenever a different app
        # becomes frontmost, which is true for essentially every "click
        # elsewhere on screen" case (clicking another app, or empty
        # desktop which activates Finder), so it doubles as that signal
        # for free.
        "front_app.sh" = ''
          #!/bin/bash
          ${sketchybarBin} --set "$NAME" label="$INFO"
          ${sketchybarBin} --set apple_menu popup.drawing=off
          ${sketchybarBin} --set "Control Centre,WiFi" popup.drawing=off
        '';

        # Wired into every other clickable item's click_script so clicking
        # anywhere else on the bar dismisses both popups.
        "close_popups.sh" = ''
          #!/bin/bash
          ${sketchybarBin} --set apple_menu popup.drawing=off
          ${sketchybarBin} --set "Control Centre,WiFi" popup.drawing=off
        '';
      };
    in {
      home.packages = [ pkgs.sketchybar ];

      xdg.configFile = lib.mapAttrs'
        (name: text: lib.nameValuePair "sketchybar/plugins/${name}" {
          executable = true;
          inherit text;
        })
        widgetPlugins
      // {
        # Bar: front-most app on the left, WiFi + date/time on the right.
        # Extend from here — https://felixkratz.github.io/SketchyBar/config.
        # SketchyBar execs this file directly, so it must be executable.
        "sketchybar/sketchybarrc" = {
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

            ${appleMenu.rc}

            ${sketchybarBin} --add item front_app left \
                --set front_app \
                    icon.drawing=off \
                    script="$PLUGIN_DIR/front_app.sh" \
                    click_script="$PLUGIN_DIR/close_popups.sh" \
                --subscribe front_app front_app_switched

            ${wifi.rc}

            ${clock.rc}

            ${sketchybarBin} --update
          '';
        };
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
