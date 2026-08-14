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

### Configuration/Tools

- Touch ID for sudo
- Window tiling (Rectangle)
- Raycast
- Top left hot corner: Show desktop
- Bottom left hot corner: Apps (Launchpad)
- Secrets management (agenix)
    - Currently exposed as env vars: `$NPM_FONT_AWESOME_TOKEN`,
      `$NPM_GITHUB_PACKAGES_TOKEN`.
    - *First use*:
        1. `mkdir -p ~/.config/age && age-keygen -o ~/.config/age/keys.txt`
           (back this file up to 1Password — losing it makes every `.age`
           file in the repo unrecoverable).
        2. `age-keygen -y ~/.config/age/keys.txt` and paste the `age1...`
           output into `secrets/secrets.nix` in place of the placeholder.
        3. For each secret listed in `secrets/secrets.nix`, run
           `cd secrets && EDITOR=vim agenix -e <name>.age` — editor opens,
           paste the value, save, quit. `git add` the `.age` file so the
           flake sees it.
        4. `ns` — secrets are decrypted to `/run/agenix/<name>` and
           re-exported in the shell by `programs.zsh.initContent` in
           `home.nix`.
    - Add another secret:
        1. Declare `age.secrets.<name>` in `flake.nix`.
        2. Add it to `secrets/secrets.nix`.
        3. `cd secrets && agenix -e <name>.age`, then `git add` it.
        4. Add a `"<VAR>:/run/agenix/<name>"` pair to the loop in
           `home.nix` if you want it in the shell environment.
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