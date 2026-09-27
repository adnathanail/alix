# Every interface module, so flake.nix only needs one import. Comment a
# line to drop that feature on the next `ns` rebuild.
#
# Wiring (in flake.nix):
#     ./modules/interface
{ username, ... }:
{
  # nix-darwin modules
  imports = [
    ./sketchybar    # SketchyBar: menu-bar replacement
    ./aerospace.nix # AeroSpace: tiling window manager + workspaces
    ./aerospace-swipe.nix # four-finger swipe between AeroSpace workspaces
    ./hammerspoon   # Hammerspoon: Fn+2 → €, Fn+3 → #
    ./other.nix     # Raycast
  ];

  # Home Manager modules
  home-manager.users.${username}.imports = [
    ./extradock.nix
  ];
}
