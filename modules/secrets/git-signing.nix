# Git SSH commit signing through 1Password (app + `op-ssh-sign` from
# modules/core/1password.nix). Needs 1Password → Settings → Developer →
# "Use the SSH agent" on; until then signed commits fail.
#
# Consumed from modules/secrets/default.nix as:
#     ./git-signing.nix
{ username, ... }:
let
  # The *public* half of the signing key; the private half never leaves
  # 1Password.
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJsvq2utLp2Y8KEL1xZPi9fggjoJDGiVcL8EjYRo4FJ";
in {
  home-manager.users.${username} = { config, ... }: {
    # The signer is 1Password's own binary, which prompts for biometrics and
    # holds the private key — nothing secret lands on disk or in Nix. `key`
    # is the public key literal; git accepts that in place of a path when
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
