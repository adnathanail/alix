# Mirrors the native WiFi menu-bar icon (aliased in — requires Screen
# Recording permission for sketchybar, see README). Click shows a small
# popup with the current network name and a shortcut to System Settings'
# Wi-Fi pane, instead of the native quick-toggle popover. The toggle
# script also closes the Apple menu popup (./apple-menu.nix) so only one
# is ever open at a time — the two menus know each other's item names by
# necessity, there being only two of them.
{ sketchybarBin }: {
  rc = ''
    ${sketchybarBin} --add alias "Control Centre,WiFi" right \
        --set "Control Centre,WiFi" \
            alias.update_freq=10 \
            click_script="$PLUGIN_DIR/wifi_menu_toggle.sh" \
            popup.align=right \
            popup.background.color=0xff1e1e2e \
            popup.background.border_color=0xff585b70 \
            popup.background.border_width=1 \
            popup.background.corner_radius=6 \
            popup.y_offset=5 \
        --add item wifi_current_network "popup.Control Centre,WiFi" \
        --set wifi_current_network \
            icon=$'' \
            icon.padding_left=4 \
            icon.padding_right=8 \
            label.align=left \
            width=200 \
        --add item wifi_open_settings "popup.Control Centre,WiFi" \
        --set wifi_open_settings \
            icon=$'' \
            icon.padding_left=4 \
            icon.padding_right=8 \
            label="Open Wi-Fi Settings" \
            label.align=left \
            width=200 \
            click_script="$PLUGIN_DIR/wifi_open_settings.sh"
  '';

  plugins = {
    # Refreshes the current-network label before showing the popup (rather
    # than polling continuously in the background).
    "wifi_menu_toggle.sh" = ''
      #!/bin/bash
      NAME=wifi_current_network "$HOME/.config/sketchybar/plugins/wifi_ssid.sh"
      ${sketchybarBin} --set apple_menu popup.drawing=off
      ${sketchybarBin} --set "Control Centre,WiFi" popup.drawing=toggle
    '';

    "wifi_open_settings.sh" = ''
      #!/bin/bash
      ${sketchybarBin} --set "Control Centre,WiFi" popup.drawing=off
      open "x-apple.systempreferences:com.apple.wifi-settings-extension"
    '';

    # Connected SSID. Both `networksetup -getairportnetwork` and `ipconfig
    # getsummary`'s SSID field are gated behind Location Services on this
    # machine — they report "not associated"/"<redacted>" respectively even
    # while genuinely connected, a system-wide privacy policy (this held
    # even querying directly from Terminal, outside any Nix/sketchybar
    # context). `networksetup -listpreferredwirelessnetworks` isn't gated
    # the same way, and macOS keeps the currently-connected network at the
    # top of that list, so this checks the interface is active first, then
    # reads that top entry as the SSID. Detects the Wi-Fi hardware port
    # name rather than hardcoding en0, since that can vary.
    "wifi_ssid.sh" = ''
      #!/bin/bash
      device=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
      if ipconfig getsummary "$device" 2>/dev/null | grep -Fxq "  Active : FALSE"; then
        ssid=""
      else
        ssid=$(networksetup -listpreferredwirelessnetworks "$device" | sed -n '2s/^\t//p')
      fi
      ${sketchybarBin} --set "$NAME" label="''${ssid:-Disconnected}"
    '';
  };
}
