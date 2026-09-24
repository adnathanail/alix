# ALix

Alex Nathanail's nix-darwin config

## Rebuilding

Rebuild `nix-darwin` config
```bash
ns  # alias for nix-switch
```

## Setting up a new Mac

A first attempt — untested end to end, so expect to adjust it. The config comes up in four
stages, **core → secrets → interface → apps**, each depending only on the ones before. For each
stage, uncomment its line in the `modules` list in `flake.nix` and rebuild.

Don't run a partial config on a Mac that already has everything installed:
`cleanup = "zap"` uninstalls (and deletes the data of) every cask the config doesn't list.

### 0. Prerequisites

[Install Lix](https://lix.systems/install/#on-any-other-linuxmacos-system)
```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

Install the Xcode command line tools (this also provides `git`)
```bash
xcode-select --install
```

Clone this repo (HTTPS — SSH keys aren't set up yet)
```bash
git clone https://github.com/adnathanail/alix.git ~/.config/nix-darwin
```

In `flake.nix`, comment out the `modules/secrets`, `modules/apps` and `modules/interface`
lines, leaving `modules/core`.

### 1. Core — terminal, editor, Claude Code, 1Password

Bootstrap `nix-darwin` (the branch must match the `nix-darwin` input in `flake.nix`, and the
`#Alexs-MacBook-Pro` must match `hostname` there — a new Mac's own hostname may differ)
```bash
sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake ~/.config/nix-darwin#Alexs-MacBook-Pro
```
This asks for `sudo` to take ownership of `/opt/homebrew`. Open a new terminal (Ghostty) and
`ns` works from here on.

Installs Ghostty, GitButler, VS Code, Claude Code, 1Password + `op`, git, zsh, python/uv/node.

Then:
1. Sign into 1Password. In Settings → Developer, turn on **Integrate with 1Password CLI** and
   **Use the SSH agent**.
2. `nix-restore-age-key` — pulls the age key from 1Password to `~/.config/age/keys.txt`.
3. Sign into Claude Code (`claude`), VS Code, GitButler.

### 2. Secrets — env-var tokens, git commit signing

Uncomment `modules/secrets`, then `ns`.

Check it worked: `ls /run/agenix/` lists the secrets, and in a new shell
`echo $NPM_FONT_AWESOME_TOKEN` is non-empty. Commits are now signed through 1Password (a
biometric prompt per commit); the public key is already on GitHub as a signing key.

Switch the repo's remote to SSH now that 1Password's agent holds the key:
```bash
git -C ~/.config/nix-darwin remote set-url origin git@github.com:adnathanail/alix.git
```

### 3. Interface — SketchyBar, Dock, Rectangle, Raycast

Uncomment `modules/interface`, then `ns`.

Then:
1. System Settings → Control Center → **Automatically hide and show the menu bar** → Always
   (SketchyBar replaces it).
2. System Settings → Privacy & Security:
    - **Accessibility**: SketchyBar (add `~/.local/libexec/sketchybar/sketchybar` — the re-signed
      copy, never a `/nix/store` path), Rectangle, Raycast
    - **Input Monitoring**: Raycast
3. Rectangle: tick **Launch on login** in its settings, then quit and reopen it.
4. Raycast: work through onboarding (let it take ⌥Space from Spotlight).
5. ExtraDock: set up the docks in-app (76pt bottom bar — `rectangle.nix` assumes it).

See [modules/interface/README.md](./modules/interface/README.md).

### 4. Apps — everything else

Sign into the Mac App Store first (App Store app → Sign In): this stage installs App Store
apps, and a failed install aborts the whole `ns`.

Uncomment `modules/apps`, then `ns`. Xcode alone is ~15 GB, so the first run is slow.

Then:
1. `sudo xcodebuild -license accept` and
   `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
2. Safari → Settings → Extensions: enable 1Password and Save to Raindrop.io.
3. MailMate: sign into each account once (OAuth in the browser) — the account config itself is
   provisioned from secrets.
4. PyCharm: disable the in-app updater and select the `ALix keymap`.
5. Sign into the rest (Slack, Todoist, Fantastical, …) and grant per-app permissions as they
   ask (Screen Recording for Slack, Calendar/Contacts/Mic/Camera per app).

Every module is now enabled; `flake.nix` should match the repo again (`git diff` is empty).

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
    - *First use*: sign into the Mac App Store (App Store app → Sign In) **before** enabling `modules/apps`, otherwise the `mas install` step fails. Downloads ~15 GB on first activation.
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
    - Rotating the key = update `signingKey` in `modules/secrets/git-signing.nix` (used for both
      the signing key and the `allowed_signers` line), then `ns`
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