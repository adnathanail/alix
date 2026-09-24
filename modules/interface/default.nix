# Every interface module, so flake.nix only needs one import. Comment a
# line to drop that feature on the next `ns` rebuild.
#
# Wiring (in flake.nix):
#     (import ./modules/interface { inherit username; })
{ username }:
{
  # nix-darwin modules
  imports = [
    (import ./sketchybar { inherit username; })    # SketchyBar: menu-bar replacement
    (import ./macos.nix { inherit username; })     # Dock, menu bar, shortcuts, Touch ID
    (import ./rectangle.nix { inherit username; }) # Rectangle: window snapping
    ./other.nix                                    # Raycast
  ];

  # Home Manager modules
  home-manager.users.${username}.imports = [
    ./extradock.nix
  ];
}
