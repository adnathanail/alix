# Core tools: the editor, terminal, VCS client and agent used every day,
# the macOS system settings (Dock, menu bar, Touch ID for sudo),
# 1Password (which bootstraps modules/secrets), and the base Home Manager
# config. This is the first stage on a fresh machine and must always be
# enabled — home.nix sets home.stateVersion.
#
# Wiring (in flake.nix):
#     ./modules/core
{ username, ... }:
{
  # nix-darwin modules
  imports = [
    ./dev.nix       # Claude Code, Ghostty, GitButler
    ./1password.nix # 1Password + CLI, nix-restore-age-key
    ./macos.nix     # Dock, menu bar, shortcuts, Touch ID
  ];

  # Home Manager modules
  home-manager.users.${username}.imports = [
    ./home.nix
    ./vscode.nix
  ];
}
