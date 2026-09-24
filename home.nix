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
    # Commit signing through 1Password: modules/secrets/1password.nix.
    settings = {
      user = {
        name = "Alex Nathanail";
        email = "7809723+adnathanail@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  home.packages = [
    pkgs.python3
    pkgs.uv
    pkgs.nodejs
    (pkgs.writeShellScriptBin "nix-switch" ''
      exec sudo darwin-rebuild switch --flake ~/.config/nix-darwin "$@"
    '')
  ];
}
