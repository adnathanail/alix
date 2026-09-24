# Every app module, so flake.nix only needs one import. Comment a line to
# drop that app on the next `ns` rebuild.
#
# Wiring (in flake.nix):
#     ./modules/apps
{ username, ... }:
{
  # nix-darwin modules
  imports = [
    ./other.nix     # Apps without their own module: casks, brews, prek, Safari extensions
    ./mailmate.nix  # MailMate: cask + account config
    ./appdev.nix    # iOS/Android app dev tooling
    ./microsoft.nix # Outlook, Word, Excel, PowerPoint
    ./macapps.nix   # Mac App Store apps (iMovie, Reeder, …)
  ];

  # Home Manager modules
  home-manager.users.${username}.imports = [
    ./rocq.nix
    ./eleventy.nix
    ./nx/nx.nix
    ./pycharm/pycharm.nix
    ./uvtools.nix
  ];
}
