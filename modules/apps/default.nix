# Every app module, so flake.nix only needs one import. Comment a line to
# drop that app on the next `ns` rebuild.
#
# Wiring (in flake.nix):
#     (import ./modules/apps { inherit username; })
{ username }:
{
  # nix-darwin modules
  imports = [
    (import ./mailmate.nix { inherit username; }) # MailMate: cask + account config
    ./appdev.nix                                  # iOS/Android app dev tooling
    ./microsoft.nix                               # Outlook, Word, Excel, PowerPoint
    ./macapps.nix                                 # Mac App Store apps (iMovie, Reeder, …)
    ./safariexts.nix                              # Safari extensions (from the App Store)
  ];

  # Home Manager modules
  home-manager.users.${username}.imports = [
    ./dev.nix           # Claude Code, prek
    ./rocq.nix
    ./eleventy.nix
    ./nx/nx.nix
    ./pycharm/pycharm.nix
    ./uvtools.nix
    ./vscode.nix
  ];
}
