# ALix

Alex Nathanail's nix-darwin config

## Rebuilding

Rebuild `nix-darwin` config
```bash
ns  # alias for nix-switch
```

Open Claude Code in this repo
```bash
ncc
```

## Updating

Ask Claude Code to run the `update-packages` skill

## Docs

- [First use](./docs/FIRST_USE.md)
- [Interface configuration](./modules/interface/README.md)
- [Updating Homebrew apps](./docs/UPDATING_HOMEBREW.md)
- [Secrets management](./modules/secrets/README.md)

## Features

### Core

Apps
- Claude Code (`nixpkgs-master`)
- VS Code (`nixpkgs-unstable`)
- 1Password
- GitButler
- Ghostty

CLI
- git
- python
- uv
- node
- op (1Password)

### Software

- PyCharm
- Orbstack
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
- Pika (colour picker with contrast checking)
- ExtraDock 5 (customizable extra docks; direct-download package, see `modules/interface/extradock.nix`)
- Xcode
- Android Studio
- 1Password for Safari
- Microsoft Word / Excel / PowerPoint
- iMovie
- Reeder (RSS/media reader — the 2024 rewrite, not Reeder Classic)
- Amphetamine (keep-awake menu bar app)
- Save to Raindrop.io

### CLIs

- prek
- [uv tools](./modules/apps/uvtools.nix)
- pnpm (Node package manager)
- nx (Nx monorepo CLI)
- gh (GitHub)
- doctl (DigitalOcean)
- Rocq (with std++ library)
- psql (PostgreSQL client)
- mysql (client only, from `mariadb.client` — `mysql`, `mysqldump`, `mysqladmin`; no server)
- poppler (PDF tools: `pdftotext`, `pdftoppm`, `pdfinfo`, etc. for Claude)
