# Shared agenix machinery — the base every secret-using module builds on:
#   - the agenix darwin module + the `agenix` CLI on PATH
#   - the age identity path
#
# The age key itself is restored on a fresh machine with
# `nix-restore-age-key`, from modules/core/1password.nix.
#
# It deliberately declares **no** `age.secrets.<name>` blocks. Secrets live
# with whatever uses them (see `modules/secrets/envvars.nix`, `modules/apps/mailmate.nix`), so
# a feature is one file rather than a change scattered across the tree.
#
# Consumed from modules/secrets/default.nix as:
#     (import ./agenix.nix { inherit agenix username; })
#
# See ./README.md for the operator flow
# (generating the age key, encrypting a new secret, fresh-machine bootstrap).
{ agenix, username }:

{ pkgs, ... }: {
  imports = [ agenix.darwinModules.default ];

  environment.systemPackages = [ agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # Decryption uses the age key at the path below (generate with
  # `age-keygen -o ~/.config/age/keys.txt`, no passphrase). Recipients live
  # in modules/secrets/secrets.nix, which the `agenix` CLI reads directly — that
  # file stays a flat map of filename → publicKeys and can't be split up.
  #
  # To add a secret:
  #   1. add it to modules/secrets/secrets.nix
  #   2. add an `age.secrets.<name>` block to the module that consumes it
  #   3. `cd modules/secrets && agenix -e agefiles/<name>.age -i ~/.config/age/keys.txt < plaintext`
  #      (agenix ignores $EDITOR when stdin isn't a TTY — see CLAUDE.md)
  #   4. `git add` the .age file so the flake sees it
  age.identityPaths = [ "/Users/${username}/.config/age/keys.txt" ];
}
