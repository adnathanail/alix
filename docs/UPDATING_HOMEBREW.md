# Updating Homebrew apps

For a full update sweep across every pinned source in this repo (flake inputs, ExtraDock,
VS Code marketplace extensions, `nx`, uv tools), ask Claude Code to run the
`update-packages` skill rather than doing it by hand.

Cask versions are **pinned in `flake.lock`**, like everything else. `homebrew-core` and
`homebrew-cask` are flake inputs, handed to `nix-homebrew.taps` with `mutableTaps = false`, so
`brew` reads those pinned checkouts instead of the live formulae.brew.sh API. A rebuild can only
ever install what the pin describes — app updates happen when *you* move the pin:

```bash
nix flake update homebrew-cask   # (and/or homebrew-core) — pull newer app versions
ns                               # activation upgrades to them
```

`brew update` is a no-op now (and `brew tap` is refused) — the taps are read-only symlinks into
the Nix store. `greedyCasks = true` makes the rebuild cover casks marked `auto_updates true`
(most GUI apps), which `brew bundle` would otherwise skip. Homebrew itself is pinned by
`nix-homebrew` — bump it with `nix flake update nix-homebrew` and rebuild.

To skip cask upgrades on a slow connection, temporarily set `upgrade = false` in `flake.nix`:

```nix
homebrew = {
  onActivation = {
    # Temporarily disable upgrades on activation
    upgrade = false;
  };
}
```
