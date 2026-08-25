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
    - Some plugins aren't in Nix, so built from source: `alekskissinger.vstikzit`, `BartInTheField.gitbutler-for-ide`, `lennardv.set-window-color-name`, `fabiospampinato.vscode-highlight`
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
- Amphetamine (keep-awake menu bar app)
- Save to Raindrop.io

### Configuration/Tools

- Touch ID for sudo
- Window tiling (Rectangle)
- Raycast
- Top left hot corner: Show desktop
- Bottom left hot corner: Apps (Launchpad)

#### Secrets management (agenix)

- Env vars: `$NPM_FONT_AWESOME_TOKEN`, `$NPM_GITHUB_PACKAGES_TOKEN`.
- MailMate account config: `mailmate-sources`, `mailmate-identities`, `mailmate-submission`
  - Activation copies them into `~/Library/Application Support/MailMate/` **only if the file is absent**

To adopt settings you've changed in the GUI, re-encrypt from the live files:
```bash
cd ~/.config/nix-darwin/secrets
for f in sources:Sources identities:Identities submission:Submission; do
  agenix -e "mailmate-${f%%:*}.age" -i ~/.config/age/keys.txt \
    < ~/Library/Application\ Support/MailMate/"${f##*:}".plist
done
```
_Note `agenix -e` ignores `$EDITOR` when stdin isn't a TTY and reads the new content from stdin instead — which is what the redirect above relies on._

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
- Shared machinery is in `agenix.nix`; **secrets live with whatever uses them** —
  `extra/envvars.nix` for shell tokens, `extra/mailmate.nix` for the MailMate account
  config. Add another secret:
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
- vibe (Mistral Vibe)
- uv (Python package/project manager) (uv tools added to path)
    - Python CLIs that aren't in nixpkgs are declared in `extra/uvtools.nix` as `<executable> = "<pinned spec>"` pairs; each becomes a PATH shim that runs `uv tool run --from <spec> <executable>`
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

## Tips

If you want to prevent cask update when on a slow connection, change `autoUpdate` in `flake.nix`

```nix
homebrew = {
  onActivation = {
    # Temporarily disable auto-update
    upgrade = false;
  };
}
```