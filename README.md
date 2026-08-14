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
- 1Password
- PyCharm
    - *First use*:
        - Disable in-app updater
        - Set keymap to `ALix keymap`
- Orbstack
- Ghostty
- Outlook
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
- Xcode
    - *First use*: sign into the Mac App Store (App Store app → Sign In) **before** the first `ns`, otherwise the `mas install` step will fail. Downloads ~15 GB on first activation.
- Android Studio
- 1Password for Safari
- Microsoft Word / Excel / PowerPoint
- iMovie
- Save to Raindrop.io

### Configuration/Tools

- Touch ID for sudo
- Window tiling (Rectangle)
- Raycast
- Top left hot corner: Show desktop
- Bottom left hot corner: Apps (Launchpad)
- Secrets management (agenix)
    - Currently exposed as env vars: `$NPM_FONT_AWESOME_TOKEN`,
      `$NPM_GITHUB_PACKAGES_TOKEN`.
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
    - All the machinery is in `extra/secrets.nix` (imported from
      `flake.nix`). Add another secret:
        1. Declare `age.secrets.<name>` in `extra/secrets.nix`.
        2. Add it to `secrets/secrets.nix`.
        3. `cd secrets && agenix -e <name>.age`, then `git add` it.
        4. If you want it as a shell env var, add a
           `write <VAR> /run/agenix/<name>` line to
           `system.activationScripts.postActivation` in
           `extra/secrets.nix` — the value lands in
           `~/.config/nix-secrets.env` on rebuild.
        5. `ns`.

### CLIs

- git
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