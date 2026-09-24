# Core tools: the editor, terminal, VCS client and agent used every day.
# Comment a line to drop that tool on the next `ns` rebuild.
#
# Wiring (in flake.nix):
#     (import ./modules/core { inherit username; })
{ username }:
{
  # nix-darwin modules
  imports = [
    (import ./dev.nix { inherit username; }) # Claude Code, Ghostty, GitButler
  ];

  # Home Manager modules
  home-manager.users.${username}.imports = [
    ./vscode.nix
  ];
}
