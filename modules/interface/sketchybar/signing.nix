# Re-signs SketchyBar with a stable self-signed identity so its privacy
# grants (System Settings → Privacy & Security) survive updates.
#
# SketchyBar and the scripts and helpers it spawns need TCC grants for some
# things — e.g. Accessibility for the config's menus helper reading the
# front app's menu bar, or the calendar's osascript keystroke that opens
# Fantastical's Mini Window. The scripts and helpers are SketchyBar's
# children, so macOS attributes their requests to SketchyBar itself.
#
# TCC pins a grant to the binary's path *and* its designated requirement.
# The nixpkgs binary is only ad-hoc signed, so its requirement is its
# cdhash, and every rebuild (and every new /nix/store path) silently voids
# every grant: the toggle stays on in System Settings but no longer
# applies. Homebrew wouldn't help — stable path, still ad-hoc signed.
#
# This copies the store binary to one fixed path and re-signs it with a
# certificate kept in agenix (modules/secrets/agefiles/sketchybar-signing-identity.age: a
# .p12 of a self-signed codeSigning cert + key, generated once with
# openssl). The requirement becomes
#     identifier "com.felixkratz.sketchybar" and certificate leaf = H"…"
# which contains no hash of the binary, so the path, identifier and cert all
# stay the same across updates and each grant only has to be given once.
# codesign accepts the cert without it being trusted (`find-identity` shows
# CSSMERR_TP_NOT_TRUSTED, which is fine), and TCC matches the leaf hash
# without checking trust.
#
# The signing keychain is throwaway: created in a temp dir, never added to
# the search list, deleted on exit. Nothing persists outside $dest.
#
# Only the launchd-run server needs this. `sketchybar --set …` CLI calls in
# the config's click scripts just message the server, so they keep using the
# store binary.
#
# Returns a script taking: <store binary> <.p12> <destination>. Run it as
# the user (see default.nix), so the keychain lives in their security
# session and $dest is user-owned.
{ pkgs }:

pkgs.writeShellScript "sign-sketchybar" ''
  set -euo pipefail
  src=$1 p12=$2 dest=$3
  identity="nix-darwin sketchybar signing"

  # Skip if $dest is already a signed copy of this exact store binary.
  if [ "$(cat "$dest.source" 2>/dev/null)" = "$src" ] \
     && /usr/bin/codesign -v "$dest" 2>/dev/null; then
    exit 0
  fi

  tmp=$(mktemp -d)
  kc="$tmp/signing.keychain-db"
  # The .p12 is only ever at rest inside agenix, so these two passwords
  # protect nothing and don't need to be secret.
  kcpass=nix-darwin
  trap '/usr/bin/security delete-keychain "$kc" 2>/dev/null || true; rm -rf "$tmp"' EXIT

  /usr/bin/security create-keychain -p "$kcpass" "$kc"
  /usr/bin/security unlock-keychain -p "$kcpass" "$kc"
  # -f is required: import guesses format from the extension, and
  # /run/agenix/<name> has none ("Unknown format in import").
  /usr/bin/security import "$p12" -f pkcs12 -k "$kc" -P nix-darwin -T /usr/bin/codesign >/dev/null
  # Lets codesign use the key without a GUI "allow access" prompt.
  /usr/bin/security set-key-partition-list -S apple-tool:,apple: -s -k "$kcpass" "$kc" >/dev/null

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest.new"
  chmod 755 "$dest.new"
  /usr/bin/codesign -f -s "$identity" --keychain "$kc" \
    --identifier com.felixkratz.sketchybar "$dest.new"
  # rename(), not overwrite: never rewrite the binary of a running process
  # in place.
  mv -f "$dest.new" "$dest"
  echo "$src" > "$dest.source"
  echo "sketchybar: signed $src -> $dest"
''
