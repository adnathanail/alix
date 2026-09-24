# Apple menu: a dropdown popup, mimicking the native Apple menu. Sits left
# of front_app (added by ./default.nix) so the bar reads Apple icon then
# the app name, same order as the real menu bar.
#
# SketchyBar has no built-in way to detect a click outside the bar
# (unresolved upstream — github.com/FelixKratz/SketchyBar/issues/655), so
# closing on an outside click is wired up by hand: every other bar item's
# click_script closes this popup (see default.nix's close_popups.sh), and
# front_app.sh closes it whenever front_app_switched fires, covering
# clicking away to the desktop or another app. This module's own toggle
# script also closes the WiFi popup (./wifi.nix) so only one is ever open
# at a time — the two menus know each other's item names by necessity,
# there being only two of them.
#
# Icons are Nerd Font (Font Awesome 4) glyphs, embedded directly as
# characters (not \u escape text) inside bash $'...' ANSI-C quoting.
{ sketchybarBin }: {
  rc = ''
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
            popup.height=0 \
        --add item apple_about popup.apple_menu \
        --set apple_about \
            icon=$'' \
            icon.padding_left=4 \
            icon.padding_right=8 \
            background.color=0x00000000 \
            background.height=26 \
            background.drawing=on \
            label="About This Mac" \
            label.align=left \
            width=160 \
            click_script="$PLUGIN_DIR/apple_about.sh" \
        --add item apple_settings popup.apple_menu \
        --set apple_settings \
            icon=$'' \
            icon.padding_left=4 \
            icon.padding_right=8 \
            background.color=0x00000000 \
            background.height=26 \
            background.drawing=on \
            label="System Settings" \
            label.align=left \
            width=160 \
            click_script="$PLUGIN_DIR/apple_settings.sh" \
        --add item apple_activity popup.apple_menu \
        --set apple_activity \
            icon=$'' \
            icon.padding_left=4 \
            icon.padding_right=8 \
            background.color=0x00000000 \
            background.height=26 \
            background.drawing=on \
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
            width=160 \
        --add item apple_logout popup.apple_menu \
        --set apple_logout \
            icon=$'' \
            icon.padding_left=4 \
            icon.padding_right=8 \
            background.color=0x00000000 \
            background.height=26 \
            background.drawing=on \
            label="Log Out" \
            label.align=left \
            width=160 \
            click_script="$PLUGIN_DIR/apple_logout.sh" \
        --add item apple_shutdown popup.apple_menu \
        --set apple_shutdown \
            icon=$'' \
            icon.padding_left=4 \
            icon.padding_right=8 \
            background.color=0x00000000 \
            background.height=26 \
            background.drawing=on \
            label="Shut Down" \
            label.align=left \
            width=160 \
            click_script="$PLUGIN_DIR/apple_shutdown.sh" \
        --add item apple_restart popup.apple_menu \
        --set apple_restart \
            icon=$'' \
            icon.padding_left=4 \
            icon.padding_right=8 \
            background.color=0x00000000 \
            background.height=26 \
            background.drawing=on \
            label="Restart" \
            label.align=left \
            width=160 \
            click_script="$PLUGIN_DIR/apple_restart.sh"
  '';

  plugins = {
    "apple_menu_toggle.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set "Control Centre,WiFi" popup.drawing=off
      ${sketchybarBin} --set apple_menu popup.drawing=toggle
    '';

    "apple_about.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set apple_menu popup.drawing=off
      open "/System/Library/CoreServices/Applications/About This Mac.app"
    '';

    "apple_settings.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set apple_menu popup.drawing=off
      open -a "System Settings"
    '';

    "apple_activity.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set apple_menu popup.drawing=off
      open -a "Activity Monitor"
    '';

    # "log out"/"shut down"/"restart" via System Events raise the same
    # confirmation dialog as picking them from the real Apple menu (not
    # suppressed), so they can't be triggered by accident.
    "apple_logout.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set apple_menu popup.drawing=off
      osascript -e 'tell application "System Events" to log out'
    '';

    "apple_shutdown.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set apple_menu popup.drawing=off
      osascript -e 'tell application "System Events" to shut down'
    '';

    "apple_restart.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set apple_menu popup.drawing=off
      osascript -e 'tell application "System Events" to restart'
    '';
  };
}
