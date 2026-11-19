# clonager: keeps track of the git clones on this laptop. Installed from its
# own flake (the `clonager` input).
#
# Its config lists every repo URL, so it lives in the private nix-private
# checkout (clonager/config.yaml) rather than in this public repo. It's
# linked to where it is, not copied into the store, so `cg config discover`
# edits it in place and changes apply immediately; commit them in
# nix-private.
#
# A darwin module rather than an HM one because HM modules don't get the
# flake inputs through specialArgs.
{ username, privateDir, clonager, ... }:
let
  configPath = "${privateDir}/clonager/config.yaml";
in
{
  home-manager.users.${username} = {
    imports = [ clonager.homeModules.default ];

    programs.clonager = {
      enable = true;
      # Strings, so the installed config is a symlink to the checkout and
      # `cg config discover` writes straight to it.
      configFile = configPath;
      configSource = configPath;
      # Where a bare `cg config discover` looks.
      discoverPaths = [ "~/Documents" "~/.config/nix-darwin" "~/.config/nix-private" ];
      # Cmd-clicking a repo's name opens it in VS Code, not Finder.
      openIn = "vscode";
      # `cg browse` starts with the most recently changed repos first,
      # showing repo names without the folders above them.
      browseSort = "recent";
      browseHideFolders = true;
    };
  };
}
