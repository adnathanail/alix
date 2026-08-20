# Shared agenix machinery — the base every secret-using module builds on:
#   - the agenix darwin module + the `agenix` CLI on PATH
#   - the age identity path
#   - `nix-restore-age-key`, the fresh-machine bootstrap helper
#
# It deliberately declares **no** `age.secrets.<name>` blocks. Secrets live
# with whatever uses them (see `extra/envvars.nix`, `extra/mailmate.nix`), so
# a feature is one file rather than a change scattered across the tree.
#
# Consumed from flake.nix as:
#     (import ./agenix.nix { inherit agenix username; })
#
# See README → "Secrets management (agenix)" for the operator flow
# (generating the age key, encrypting a new secret, fresh-machine bootstrap).
{ agenix, username }:

{ pkgs, ... }: {
  imports = [ agenix.darwinModules.default ];

  environment.systemPackages = [ agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # Decryption uses the age key at the path below (generate with
  # `age-keygen -o ~/.config/age/keys.txt`, no passphrase). Recipients live
  # in secrets/secrets.nix, which the `agenix` CLI reads directly — that
  # file stays a flat map of filename → publicKeys and can't be split up.
  #
  # To add a secret:
  #   1. add it to secrets/secrets.nix
  #   2. add an `age.secrets.<name>` block to the module that consumes it
  #   3. `cd secrets && agenix -e <name>.age -i ~/.config/age/keys.txt < plaintext`
  #      (agenix ignores $EDITOR when stdin isn't a TTY — see CLAUDE.md)
  #   4. `git add` the .age file so the flake sees it
  age.identityPaths = [ "/Users/${username}/.config/age/keys.txt" ];

  home-manager.users.${username} = { pkgs, ... }: {
    home.packages = [
      # Fetches the age identity from 1Password on a fresh machine.
      # Refuses to overwrite an existing key. Upload command (run once,
      # after key generation) is in the README.
      (pkgs.writeShellScriptBin "nix-restore-age-key" ''
        set -euo pipefail
        key="$HOME/.config/age/keys.txt"
        if [ -e "$key" ]; then
          echo "Refusing to overwrite existing $key — move it aside first." >&2
          exit 1
        fi
        mkdir -p "$(dirname "$key")"
        op document get "nix-darwin age key" --vault Private --out-file "$key"
        chmod 600 "$key"
        echo "Restored age key to $key"
      '')
    ];
  };
}
