# Re-signs a Nix-built binary or .app bundle with a stable self-signed
# identity so its privacy grants (System Settings → Privacy & Security)
# survive updates. Used for SketchyBar (./sketchybar), aerospace-swipe
# (./aerospace-swipe.nix) and AeroSpace (./aerospace.nix).
#
# SketchyBar and the scripts and helpers it spawns need TCC grants for some
# things — e.g. Accessibility for the config's menus helper reading the
# front app's menu bar, or the calendar's osascript keystroke that opens
# Fantastical's Mini Window. The scripts and helpers are SketchyBar's
# children, so macOS attributes their requests to SketchyBar itself.
# aerospace-swipe needs Accessibility for its event tap, AeroSpace for
# moving windows.
#
# TCC pins a grant to the binary's path *and* its designated requirement.
# The nixpkgs-built binaries are only ad-hoc signed, so their requirement is
# their cdhash, and every rebuild (and every new /nix/store path) silently
# voids every grant: the toggle stays on in System Settings but no longer
# applies. Homebrew wouldn't help — stable path, still ad-hoc signed.
#
# This copies the store binary to one fixed path and re-signs it with a
# certificate kept in agenix (modules/secrets/agefiles/alix-local-signing-identity.age:
# a .p12 of a self-signed codeSigning cert + key, generated once with
# openssl). The requirement becomes
#     identifier "<identifier>" and certificate root = H"…"
# (root, not leaf, because rcodesign phrases it that way; for a self-signed
# cert they're the same cert). It contains no hash of the binary, so the
# path, identifier and cert all stay the same across updates and each grant
# only has to be given once. TCC matches the cert hash without checking
# trust, so the cert never needs trusting. Sharing the cert between binaries
# is fine: the identifier keeps their requirements, and so their grants,
# apart.
#
# Signing uses rcodesign (apple-codesign), which reads the .p12 directly.
# Apple's codesign can only sign from a keychain, and it ignores
# `--keychain` for one that isn't on the user's search list ("no identity
# found"), so using it meant either importing the key into the login
# keychain or temporarily rewriting the search list. rcodesign touches
# neither; nothing persists outside $dest.
#
# Only the launchd-run binary needs this. E.g. `sketchybar --set …` CLI
# calls in SketchyBar's click scripts just message the server, so they keep
# using the store binary.
#
# A bundle (AeroSpace.app) is signed whole — its main executable and its
# resources — and keeps its own CFBundleIdentifier, so pass no
# `identifier` for one.
#
# Returns a script taking: <store binary or .app> <.p12> <destination>. Run
# it as the user (see sketchybar/default.nix), so $dest is user-owned.
# `$dest.source` records the store path the copy was made from, so a caller
# can tell whether there's a new copy (see aerospace.nix).
{ pkgs, name, identifier ? null }:

pkgs.writeShellScript "sign-${name}" ''
  set -euo pipefail
  src=$1 p12=$2 dest=$3

  # Skip if $dest is already a signed copy of this exact store binary.
  if [ "$(cat "$dest.source" 2>/dev/null)" = "$src" ] \
     && /usr/bin/codesign -v "$dest" 2>/dev/null; then
    exit 0
  fi

  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest.new"
  # The .p12 is only ever at rest inside agenix, so its password protects
  # nothing and doesn't need to be secret. rcodesign logs every step, so
  # its output is only shown if it fails.
  if ! out=$(${pkgs.rcodesign}/bin/rcodesign sign \
      --p12-file "$p12" --p12-password nix-darwin \
      ${pkgs.lib.optionalString (identifier != null) "--binary-identifier ${identifier}"} \
      "$src" "$dest.new" 2>&1); then
    echo "$out" >&2
    exit 1
  fi
  # rename(), not overwrite: never rewrite the binary of a running process
  # in place. A bundle is a directory, which mv can't rename over, so the
  # old one is moved aside first.
  if [ -d "$dest.new" ]; then
    rm -rf "$dest.old"
    [ ! -e "$dest" ] || mv "$dest" "$dest.old"
    mv "$dest.new" "$dest"
    rm -rf "$dest.old"
  else
    chmod 755 "$dest.new"
    mv -f "$dest.new" "$dest"
  fi
  echo "$src" > "$dest.source"
  echo "${name}: signed $src -> $dest"
''
