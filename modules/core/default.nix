# Core tools: the editor, terminal, VCS client and agent used every day,
# 1Password (which bootstraps modules/secrets), and the base Home Manager
# config. This is the first stage on a fresh machine and must always be
# enabled — home.nix sets home.stateVersion.
#
# Wiring (in flake.nix):
#     (import ./modules/core { inherit username; })
{ username }:
{
  # nix-darwin modules
  imports = [
    (import ./dev.nix { inherit username; })       # Claude Code, Ghostty, GitButler
    (import ./1password.nix { inherit username; }) # 1Password + CLI, nix-restore-age-key
  ];

  # Home Manager modules
  home-manager.users.${username}.imports = [
    ./home.nix
    ./vscode.nix
  ];
}
