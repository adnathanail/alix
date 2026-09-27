# Apps kept around but not actively used — commented out, so not installed.
# Uncomment a line to bring it back on the next `ns`.
#
# Consumed from flake.nix as:
#     ./modules/graveyard.nix
{ username, pkgs, ... }: {
  home-manager.users.${username}.home.packages = [
    # pkgs.ghidra
    # pkgs.rectangle # window snapping, replaced by AeroSpace; its prefs are in git history (modules/interface/rectangle.nix)
  ];

  homebrew.casks = [
    # "little-snitch"
    # "micro-snitch"
    # "bartender"
  ];
}
