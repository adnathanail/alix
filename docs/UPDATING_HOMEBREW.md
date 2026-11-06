# Updating Homebrew apps

For a full update sweep across every pinned source in this repo (flake inputs, ExtraDock,
VS Code marketplace extensions, `nx`, uv tools, Mac App Store apps), ask Claude Code to run the
`update-packages` skill rather than doing it by hand.

`ns` installs what's newly declared and removes what's no longer declared, but never upgrades
anything Homebrew or the Mac App Store already installed (`onActivation.upgrade = false` in
`flake.nix`). Upgrades are a separate step.

## Casks and formulae

Versions are **pinned in `flake.lock`**, like everything else. `homebrew-core` and
`homebrew-cask` are flake inputs, handed to `nix-homebrew.taps` with `mutableTaps = false`, so
`brew` reads those pinned checkouts instead of the live formulae.brew.sh API. Newer versions
only become available when you move the pin:

```bash
nix flake update homebrew-cask   # (and/or homebrew-core) — pull newer app metadata
ns                               # points brew at the new pin
brew outdated --greedy           # see what's behind it
brew upgrade --greedy            # upgrade all of it, or name specific casks and formulae
```

`--greedy` includes casks marked `auto_updates true` (most GUI apps), which `brew` otherwise
skips, and which matters because self-updating is deliberately off for some of them (Ghostty,
Microsoft AutoUpdate).

It also includes `version :latest` casks (`font-sf-pro`, `font-sf-mono`). The tap pin doesn't
hold these back: they download whatever Apple currently hosts, so they show as outdated whenever
that file changes.

`brew update` is a no-op (and `brew tap` is refused) because the taps are read-only symlinks into
the Nix store. Homebrew itself is pinned by `nix-homebrew`: bump it with
`nix flake update nix-homebrew` and rebuild.

## Mac App Store apps

These can't be pinned, since the App Store only serves the current version:

```bash
mas outdated
sudo mas upgrade              # upgrade all of them, or pass specific app IDs
```

macOS can also update these by itself, through System Settings → App Store → Automatic Updates.
