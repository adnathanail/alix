# Core dev tools: Claude Code, Ghostty, GitButler.
#
# Consumed from modules/core/default.nix as:
#     (import ./dev.nix { inherit username; })
{ username }:
{ ... }: {
  # Ghostty needs Homebrew: pkgs.ghostty on Darwin is fragile (Swift/Xcode
  # toolchain). GitButler needs /Applications.
  homebrew.casks = [ "ghostty" "gitbutler" ];

  home-manager.users.${username} = { pkgs, ... }: {
    # Claude Code from raw nixpkgs master (pkgs.master) — see the
    # nixpkgs-master input comment in flake.nix. Manage config here:
    # settings = { theme = "dark"; };
    programs.claude-code = {
      enable = true;
      package = pkgs.master.claude-code;
    };

    # Stop Claude Code self-updating into the read-only store;
    # you update it via Nix instead.
    home.sessionVariables.DISABLE_AUTOUPDATER = "1";

    # Work uses a separate Anthropic account; CLAUDE_CONFIG_DIR points
    # Claude Code at an isolated config/credentials dir (default is
    # ~/.claude) so logging in here doesn't clobber the personal session.
    programs.zsh.shellAliases.claude-work = "CLAUDE_CONFIG_DIR=$HOME/.claude-work claude";

    # Ghostty config. The file is Nix-owned so the first-launch auto-update
    # prompt is suppressed declaratively. Edits made in the app won't
    # persist — change this block and rebuild.
    xdg.configFile."ghostty/config".text = ''
      auto-update = off
    '';
  };
}
