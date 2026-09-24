# 1Password: the app, its CLI (`op`), the Safari extension, and git commit
# signing through it.
#
# Homebrew, not Nix: pkgs._1password-gui refuses to run outside
# /Applications, and the desktop ↔ CLI biometric handshake verifies
# AgileBits' signature on `op`, which Nix's wrap step invalidates.
#
# Also relied on by `nix-restore-age-key` (agenix.nix), which fetches the
# age key with `op`.
#
# Consumed from modules/secrets/default.nix as:
#     (import ./1password.nix { inherit username; })
{ username }:
{ ... }:
let
  # The *public* half of the signing key; the private half never leaves
  # 1Password.
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJsvq2utLp2Y8KEL1xZPi9fggjoJDGiVcL8EjYRo4FJ";
in {
  homebrew.casks = [ "1password" "1password-cli" ];

  # Safari extension, from the Mac App Store. Enable it in Safari →
  # Settings → Extensions after install.
  homebrew.masApps."1Password for Safari" = 1569813296;

  home-manager.users.${username} = { config, ... }: {
    # SSH commit signing through 1Password. The signer is 1Password's own
    # binary (the cask above), which prompts for biometrics and holds the
    # private key — nothing secret lands on disk or in Nix. `key` is the
    # public key literal; git accepts that in place of a path when
    # gpg.format = "ssh". signByDefault also signs tags.
    programs.git.signing = {
      format = "ssh";
      signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      key = signingKey;
      signByDefault = true;
    };

    # Lets `git log --show-signature` verify your own commits locally;
    # without it git can sign but reports "No signature" on verify.
    programs.git.settings.gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";

    # Trusted signing keys for local verification. Add other people's keys
    # here as `<email> <key type> <public key>` lines if you need to verify
    # their commits too.
    xdg.configFile."git/allowed_signers".text =
      "7809723+adnathanail@users.noreply.github.com ${signingKey}\n";
  };
}
