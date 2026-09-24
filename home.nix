{ pkgs, config, ... }: {
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
    # SSH commit signing through 1Password. The signer is 1Password's own
    # binary (Homebrew cask, see flake.nix), which prompts for biometrics
    # and holds the private key — nothing secret lands on disk or in Nix.
    # `key` is the *public* key literal; git accepts that in place of a
    # path when gpg.format = "ssh". signByDefault also signs tags.
    signing = {
      format = "ssh";
      signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJsvq2utLp2Y8KEL1xZPi9fggjoJDGiVcL8EjYRo4FJ";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "Alex Nathanail";
        email = "7809723+adnathanail@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      # Lets `git log --show-signature` verify your own commits locally;
      # without it git can sign but reports "No signature" on verify.
      gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
    };
  };

  # Trusted signing keys for local verification. Add other people's keys
  # here as `<email> <key type> <public key>` lines if you need to verify
  # their commits too.
  xdg.configFile."git/allowed_signers".text =
    "7809723+adnathanail@users.noreply.github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJsvq2utLp2Y8KEL1xZPi9fggjoJDGiVcL8EjYRo4FJ\n";

  home.packages = [
    pkgs.python3
    pkgs.uv
    pkgs.nodejs
    pkgs.pnpm
    pkgs.gh
    pkgs.doctl
    pkgs.postgresql
    pkgs.mariadb.client
    pkgs.ghidra
    (pkgs.writeShellScriptBin "nix-switch" ''
      exec sudo darwin-rebuild switch --flake ~/.config/nix-darwin "$@"
    '')
  ];

  # Ghostty config. The app itself comes from Homebrew (see flake.nix), but
  # the config file is Nix-owned so the first-launch auto-update prompt is
  # suppressed declaratively. Edits made in the app won't persist — change
  # this block and rebuild.
  xdg.configFile."ghostty/config".text = ''
    auto-update = off
  '';
}
