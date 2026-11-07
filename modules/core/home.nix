{ pkgs, ... }: {
  home.stateVersion = "25.11";

  programs.zsh = {
    enable = true;
    shellAliases = {
      ns = "nix-switch";
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    # Commit signing through 1Password: modules/secrets/git-signing.nix.
    settings = {
      user = {
        name = "Alex Nathanail";
        email = "7809723+adnathanail@users.noreply.github.com";
      };
      # Commit messages, interactive rebases, and `but`'s "reword with
      # editor". `but tui`'s `o` uses GitButler's own program list instead
      # (modules/core/dev.nix).
      core.editor = "hx";
      init.defaultBranch = "main";
      pull.rebase = true;
      fetch.prune = true;
    };
  };

  home.packages = [
    pkgs.python3
    pkgs.master.uv
    pkgs.nodejs
    # Names the configuration explicitly: without `#<name>`, darwin-rebuild
    # picks it by `scutil --get LocalHostName`, which differs on a new Mac.
    # Keep in step with `hostname` in flake.nix.
    (pkgs.writeShellScriptBin "nix-switch" ''
      exec sudo darwin-rebuild switch --flake ~/.config/nix-darwin#Alexs-MacBook-Pro "$@"
    '')
  ];
}
