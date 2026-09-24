# ALix

Alex Nathanail's nix-darwin config

## Rebuilding

Rebuild `nix-darwin` config
```bash
ns  # alias for nix-switch
```

## First use

[Install Lix](https://lix.systems/install/#on-any-other-linuxmacos-system)
```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

Install XCode dev tools
```bash
xcode-select --install
```

Bootstrap `nix-darwin`
```bash
nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix-darwin
```

## Features

### Software

- Claude Code
    - Tracks raw `nixpkgs` `master` (its own flake input, `nixpkgs-master`) rather than the
      `nixpkgs-unstable` channel branch, to avoid the channel-promotion lag — see `flake.nix`
- VS Code (w/ plugins)
    - Tracks `nixpkgs-unstable`; the 26.05 pin lags several releases behind
- 1Password
- PyCharm
    - *First use*:
        - Disable in-app updater
        - Set keymap to `ALix keymap`
- GitButler
- Orbstack
- Ghostty
- Outlook
- MailMate (2.0 beta)
  - Includes `emate` CLI at `/Applications/MailMate.app/Contents/Resources/emate`
  - Account config lives in three small files: `~/Library/Application Support/MailMate/` — `Sources.plist` (IMAP), `Submission.plist` (SMTP), `Identities.plist` (from-addresses).
    - Just email address/config no passwords, will ask for auth on first use
  - Outlook.com/Hotmail needs OAuth on **both** IMAP and SMTP, and both hosts must be
    `*.office365.com` — the setup wizard gets the SMTP host wrong. See CLAUDE.md →
    *Per-tool notes* → MailMate before touching account settings
- Mimestream (Gmail client)
- Todoist
- Slack
- Fantastical
- Spotify
- WhatsApp
- Google Drive
- Steam
- Discord
- CapCut
- Zoom
- Audacity
- VLC
- GIMP
- Ghidra
- UTM
- Anki
- Private Internet Access (VPN)
- Telegram
- Signal
- Brave Browser
- Raindrop.io
- DeepL (translator)
- DockFlow (Dock preset switcher)
- ExtraDock 5 (customizable extra docks; direct-download package, see `modules/interface/extradock.nix`)
- Xcode
    - *First use*: sign into the Mac App Store (App Store app → Sign In) **before** the first `ns`, otherwise the `mas install` step will fail. Downloads ~15 GB on first activation.
- Android Studio
- 1Password for Safari
- Microsoft Word / Excel / PowerPoint
- iMovie
- Reeder (RSS/media reader — the 2024 rewrite, not Reeder Classic)
- Amphetamine (keep-awake menu bar app)
- Save to Raindrop.io

### CLIs

- git
    - Commits and tags are SSH-signed by default, with 1Password holding the private key
      and `op-ssh-sign` doing the signing (biometric prompt per signature)
    - *First use on a fresh machine*: 1Password → Settings → Developer → **Use the SSH
      agent**, and add the public key to GitHub under **Settings → SSH and GPG keys** as a
      **Signing key** (a key added only as an Authentication key won't mark commits verified)
    - Rotating the key = update `programs.git.signing.key` and the `allowed_signers` line in
      `home.nix`, then `ns`
- prek
- python
- uv (Python package/project manager) (uv tools added to path)
    - Python CLIs that aren't in nixpkgs are declared in `modules/apps/uvtools.nix` as `<executable> = "<pinned spec>"` pairs; each becomes a PATH shim that runs `uv tool run --from <spec> <executable>`
    - uv resolves and caches the environment under `~/.cache/uv` on first run, so the first invocation of each tool needs network access; keep the `==` version pins
- node
- pnpm (Node package manager)
- nx (Nx monorepo CLI)
- gh (GitHub)
- doctl (DigitalOcean)
- op (1Password)
- Rocq (with std++ library)
- psql (PostgreSQL client)
- mysql (client only, from `mariadb.client` — `mysql`, `mysqldump`, `mysqladmin`; no server)
- poppler (PDF tools: `pdftotext`, `pdftoppm`, `pdfinfo`, etc. for Claude)

### Configuration/Tools

See [modules/interface/README.md](./modules/interface/README.md).

### Secrets management (agenix)

See [modules/secrets/README.md](./modules/secrets/README.md).

## Tips

### Updating Homebrew apps

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