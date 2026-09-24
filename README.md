# ALix

Alex Nathanail's nix-darwin config

## Rebuilding

Rebuild `nix-darwin` config
```bash
ns  # alias for nix-switch
```

## Updating

Ask Claude Code to run the `update-packages` skill

## Docs

- [First use](./docs/FIRST_USE.md)
- [Interface configuration](./modules/interface/README.md)
- [Updating Homebrew apps](./docs/UPDATING_HOMEBREW.md)
- [Interface configuration](./modules/secrets/README.md)

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
