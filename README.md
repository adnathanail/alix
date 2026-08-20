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
- VS Code (w/ plugins)
    - Tracks `nixpkgs-unstable`; the 26.05 pin lags several releases behind
    - Some plugins aren't in Nix, so built from source: `alekskissinger.vstikzit`, `BartInTheField.gitbutler-for-ide`
- 1Password
- PyCharm
    - *First use*:
        - Disable in-app updater
        - Set keymap to `ALix keymap`
- GitButler
- Orbstack
- Ghostty
- Outlook
- MailMate
    - Homebrew cask — macOS-only proprietary IMAP client, not in nixpkgs
    - The cask is `auto_updates`, so MailMate updates itself (Sparkle) rather than through `ns`
    - Ships an `emate` CLI at `/Applications/MailMate.app/Contents/Resources/emate`
    - *First use*: add accounts (App-specific password for iCloud/Gmail-style 2FA accounts);
      unlicensed use falls back to the free/limited mode after the trial
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
- Little Snitch
- Micro Snitch
- Raindrop.io
- DeepL (translator)
- Xcode
    - *First use*: sign into the Mac App Store (App Store app → Sign In) **before** the first `ns`, otherwise the `mas install` step will fail. Downloads ~15 GB on first activation.
- Android Studio
- 1Password for Safari
- Microsoft Word / Excel / PowerPoint
- iMovie
- Reeder (RSS/media reader — the 2024 rewrite, not Reeder Classic)
- Save to Raindrop.io

### Configuration/Tools

- Touch ID for sudo
- Window tiling (Rectangle)
- Raycast
- Top left hot corner: Show desktop
- Bottom left hot corner: Apps (Launchpad)

#### Secrets management (agenix)

- Env vars: `$NPM_FONT_AWESOME_TOKEN`, `$NPM_GITHUB_PACKAGES_TOKEN`.
- *First use on a brand-new key* (once ever):
    1. `mkdir -p ~/.config/age && age-keygen -o ~/.config/age/keys.txt`
    2. Back the key up to 1Password:
        `op document create ~/.config/age/keys.txt --title "nix-darwin age key" --vault Private`
        (rotate the item with `op document edit "nix-darwin age key" ~/.config/age/keys.txt`
        if you regenerate the key later).
    3. `age-keygen -y ~/.config/age/keys.txt` and paste the `age1...`
        output into `secrets/secrets.nix` in place of the placeholder.
    4. For each secret listed in `secrets/secrets.nix`, run
        `cd secrets && EDITOR=vim agenix -e <name>.age`. `git add` the
        `.age` file so the flake sees it.
    5. `ns` — secrets decrypt to `/run/agenix/<name>` and are exported
        in the shell by `programs.zsh.initContent` in `home.nix`.
- *First use on a fresh machine* (key already in 1Password):
    1. Bootstrap up to the point where `op` is on PATH (see top of
        this file).
    2. `nix-restore-age-key` — pulls the key from 1Password to
        `~/.config/age/keys.txt` with mode 0600.
    3. `ns`.
- Shared machinery is in `extra/agenix.nix`; **secrets live with whatever uses them** —
  `extra/envvars.nix` for shell tokens. Add another secret:
    1. Declare `age.secrets.<name>` in the module that consumes it (a new
        `extra/<feature>.nix` if it's a new feature — add it to `modules` in `flake.nix`).
    2. Add it to `secrets/secrets.nix` — that file is read by the `agenix` CLI, so it stays
        one flat list regardless of which module uses the secret.
    3. `cd secrets && agenix -e <name>.age -i ~/.config/age/keys.txt < plaintext`,
        then `git add` it. Flakes only see git-tracked files, so an unstaged `.age`
        is invisible to `ns`.
    4. If you want it as a shell env var, add a
        `write <VAR> /run/agenix/<name>` line to
        `system.activationScripts.postActivation` in
        `extra/envvars.nix` — the value lands in
        `~/.config/nix-secrets.env` on rebuild.
    5. `ns`.

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
- node
- pnpm (Node package manager)
- nx (Nx monorepo CLI)
- gh (GitHub)
- doctl (DigitalOcean)
- op (1Password)
- Rocq (with std++ library)
- psql (PostgreSQL client)