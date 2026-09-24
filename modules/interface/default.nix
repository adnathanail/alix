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
    ./macos.nix     # Dock, menu bar, shortcuts, Touch ID
    ./rectangle.nix # Rectangle: window snapping
    ./other.nix     # Raycast
  ];

  # Home Manager modules
  home-manager.users.${username}.imports = [
    ./extradock.nix
  ];
}
