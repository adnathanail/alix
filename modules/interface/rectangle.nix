# Rectangle — Magnet-style window snapping. Every setting changed from
# Rectangle's defaults is declared below; Rectangle only writes changed
# settings to ~/Library/Preferences/com.knollsoft.Rectangle.plist, so this
# list is the whole config. Keys it writes for its own state (save-panel
# location, menu-bar icon position, version tracking) are left alone.
#
# `defaults write` only sets the listed keys: removing one here leaves its
# last value in the plist, and in-app changes to a listed key are
# overwritten on the next `ns`. Rectangle reads its prefs at launch, so
# quit and reopen it after a rebuild that changes them.
#
# A darwin module (the prefs are system.defaults) that installs the app
# through Home Manager, so it stays at ~/Applications/Home Manager Apps/
# and keeps its Accessibility grant.
#
# Consumed from modules/interface/default.nix as:
#     ./rectangle.nix
{ username, pkgs, ... }: {
  home-manager.users.${username}.home.packages = [ pkgs.rectangle ];

  system.defaults.CustomUserPreferences."com.knollsoft.Rectangle" = {
    # Keep snapped/maximised windows clear of the custom bars, neither of
    # which reserves screen space the way the native menu bar and Dock do.
    # SketchyBar (modules/interface/sketchybar/config/bar.lua) is 40pt;
    # macOS already reserves 32pt for the hidden notch menu bar.
    screenEdgeGapTop = 8;
    # ExtraDock's bottom docks: 76pt bar thickness, 0pt edge gap
    # (in-app settings, not Nix-managed — update this if they change).
    screenEdgeGapBottom = 76;

    # Rectangle's own default shortcuts rather than Spectacle's.
    alternateDefaultShortcuts = true;
    # Allow shortcuts with no modifier key.
    allowAnyShortcut = true;
    # What repeating the same shortcut does (as chosen in the UI).
    subsequentExecutionMode = 1;

    # Todo-mode shortcuts. modifierFlags 786432 = ⌃ (0x40000) + ⌥ (0x80000);
    # keyCodes are macOS virtual key codes.
    toggleTodo = { keyCode = 11; modifierFlags = 786432; }; # ⌃⌥B
    reflowTodo = { keyCode = 45; modifierFlags = 786432; }; # ⌃⌥N

    # Sparkle updater off — updates come from nixpkgs.
    SUEnableAutomaticChecks = false;

    # Ticks the checkbox, but macOS keeps login items in its own registry
    # (SMAppService), so on a fresh machine tick it once in the UI too.
    launchOnLogin = true;

    # Don't show the "macOS has its own window tiling" notice again.
    internalTilingNotified = true;
  };
}
