# The original hand-rolled bash bar: Apple menu + front app on the left,
# WiFi, battery and clock on the right. Currently disconnected in favour of
# ../felixkratz — swap `barConfig` in ../default.nix to bring it back.
#
# Each bar widget is its own file — apple-menu.nix, wifi.nix, battery.nix,
# clock.nix — returning `{ rc, plugins }`: `rc` is the sketchybarrc fragment
# that adds the widget's items, `plugins` is an attrset of plugin-script
# filename → contents. This file concatenates the rc fragments into one
# sketchybarrc (SketchyBar execs it once at startup, so it has to be a single
# script) and merges the plugin attrsets into one directory. front_app and
# close_popups.sh live here rather than in a widget file since they're
# cross-cutting — they reference both the Apple menu and WiFi popups by name.
#
# Returns the finished config directory; ../default.nix links it to
# ~/.config/sketchybar.
{ pkgs, lib, sketchybarBin }:

let
  appleMenu = import ./apple-menu.nix { inherit sketchybarBin; };
  wifi = import ./wifi.nix { inherit sketchybarBin; };
  battery = import ./battery.nix { inherit sketchybarBin; };
  clock = import ./clock.nix { inherit sketchybarBin; };

  plugins = appleMenu.plugins // wifi.plugins // battery.plugins // clock.plugins // {
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

  # Extend from here — https://felixkratz.github.io/SketchyBar/config.
  sketchybarrc = ''
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

    ${battery.rc}

    ${clock.rc}

    ${sketchybarBin} --update
  '';
in
# SketchyBar execs sketchybarrc directly, so it and the plugins must be
# executable.
pkgs.runCommand "sketchybar-config-classic" { } ''
  mkdir -p $out/plugins
  install -m 755 ${pkgs.writeText "sketchybarrc" sketchybarrc} $out/sketchybarrc
  ${lib.concatStrings (lib.mapAttrsToList (name: text: ''
    install -m 755 ${pkgs.writeText name text} $out/plugins/${name}
  '') plugins)}
''
