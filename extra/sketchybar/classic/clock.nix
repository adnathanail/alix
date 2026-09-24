# No native Fantastical menu-bar icon left to mirror, so this item is just
# a date/time label; click opens Fantastical's Mini Window rather than the
# full app.
{ sketchybarBin }: {
  rc = ''
    ${sketchybarBin} --add item clock right \
        --set clock \
            icon.drawing=off \
            update_freq=1 \
            script="$PLUGIN_DIR/clock.sh" \
            click_script="$PLUGIN_DIR/close_popups.sh && $PLUGIN_DIR/open_calendar.sh"
  '';

  plugins = {
    "clock.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set "$NAME" label="$(date '+%a %d %b %H:%M:%S')"
    '';

    # Fantastical has no URL scheme or AppleScript command for its Mini
    # Window (the menu-bar popover) — it only opens via a system-wide
    # keyboard shortcut (Fantastical → Settings → General). This simulates
    # that shortcut (default Control+Option+Space, key code 49 = space)
    # through System Events instead of launching the full app. First click
    # will likely prompt for Accessibility permission, same as Rectangle/
    # Raycast — see README's manual-setup section.
    "open_calendar.sh" = ''
      #!/bin/bash
      osascript -e 'tell application "System Events" to key code 49 using {control down, option down}'
    '';
  };
}
