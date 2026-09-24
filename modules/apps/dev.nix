# Dev CLIs that track a newer nixpkgs than the stable pin.
{ pkgs, ... }: {
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

  home.packages = [
    # Rust reimplementation of pre-commit; from unstable because stable
    # lags this fast-moving 0.x tool.
    pkgs.unstable.prek
  ];
}
