# 1Password: the app, its CLI (`op`), and `nix-restore-age-key`.
#
# In core rather than secrets because it's what bootstraps secrets: on a
# fresh machine, sign into 1Password and run `nix-restore-age-key` *before*
# enabling modules/secrets, so agenix can decrypt on its first run.
#
# Homebrew, not Nix: pkgs._1password-gui refuses to run outside
# /Applications, and the desktop ↔ CLI biometric handshake verifies
# AgileBits' signature on `op`, which Nix's wrap step invalidates.
#
# Git commit signing through 1Password lives in modules/secrets/git-signing.nix;
# the Safari extension in modules/apps/other.nix.
#
# Consumed from modules/core/default.nix as:
#     (import ./1password.nix { inherit username; })
{ username }:
{ ... }: {
  homebrew.casks = [ "1password" "1password-cli" ];

  home-manager.users.${username} = { pkgs, ... }: {
    home.packages = [
      # Fetches the age identity (used by modules/secrets) from 1Password on
      # a fresh machine. Needs the 1Password app signed in with Settings →
      # Developer → "Integrate with 1Password CLI" on. Refuses to overwrite
      # an existing key. Upload command (run once, after key generation) is
      # in modules/secrets/README.md.
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
