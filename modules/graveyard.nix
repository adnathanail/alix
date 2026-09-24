# Apps kept around but not actively used — commented out, so not installed.
# Uncomment a line to bring it back on the next `ns`.
#
# Consumed from flake.nix as:
#     ./modules/graveyard.nix
{ username, pkgs, ... }: {
  home-manager.users.${username}.home.packages = [
    # pkgs.ghidra
  ];

  homebrew.casks = [
    # "little-snitch"
    # "micro-snitch"
    # "bartender"
  ];
}
