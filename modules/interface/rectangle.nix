# Rectangle — Magnet-style window snapping. Configure keybindings/snap
# areas in Rectangle's own preferences UI; it persists them to
# ~/Library/Preferences/com.knollsoft.Rectangle.plist (not Nix-managed,
# except the screen-edge gaps below).
#
# A darwin module (the prefs are system.defaults) that installs the app
# through Home Manager, so it stays at ~/Applications/Home Manager Apps/
# and keeps its Accessibility grant.
#
# Wiring (in flake.nix):
#     (import ./modules/interface/rectangle.nix { inherit username; })
{ username }:
{ pkgs, ... }: {
  home-manager.users.${username}.home.packages = [ pkgs.rectangle ];

  # Rectangle: keep snapped/maximised windows clear of the custom bars,
  # neither of which reserves screen space the way the native menu bar
  # and Dock do. Only these keys are Nix-managed — the rest of
  # Rectangle's prefs (shortcuts etc.) still live in its UI. Rectangle
  # reads them at launch, so restart it after a rebuild that changes
  # them.
  system.defaults.CustomUserPreferences."com.knollsoft.Rectangle" = {
    # SketchyBar (modules/interface/sketchybar/config/bar.lua) is 40pt;
    # macOS already reserves 32pt for the hidden notch menu bar.
    screenEdgeGapTop = 8;
    # ExtraDock's bottom docks: 76pt bar thickness, 0pt edge gap
    # (in-app settings, not Nix-managed — update this if they change).
    screenEdgeGapBottom = 76;
  };
}
