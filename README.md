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
- ExtraDock 5 (customizable extra docks; direct-download package, see `extra/extradock.nix`)
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
    - Screen-edge gaps are Nix-managed (`flake.nix`): 8pt at the top so windows clear the 40pt SketchyBar, 76pt at the bottom for ExtraDock's docks. Quit and reopen Rectangle after `ns` for changes to apply
- Raycast
- SketchyBar (menu-bar replacement, see `extra/sketchybar/`)
    - FelixKratz's own Lua config (`extra/sketchybar/config/`, vendored from his dotfiles), linked to `~/.config/sketchybar/` — https://felixkratz.github.io/SketchyBar/config. Apple menu, the front app's menus / spaces toggle, Spotify now-playing (cover art; hover or click for track details and back / play-pause / next — reworked to use Spotify's own notifications and AppleScript, as SketchyBar's built-in media event is dead since macOS 15.4), CPU graph, network up/down + WiFi popup, volume + output-device popup, battery, calendar (click opens Fantastical's Mini Window). The Wi-Fi popup also has an "Open Wi-Fi Settings" row. After unlocking the screen the bar animates back in (slides down, rounded corners, then fades to its colour). The bar sits above the native menu bar (`topmost = on`), so hovering at the top of the screen doesn't reveal it. An eye icon just left of the CPU graph shows the native macOS menu bar (auto-hide Always → Never) and hides SketchyBar; a matching icon in the native menu bar (`extra/sketchybar/menubar-return.m`, its own launchd agent) hides it again and returns to SketchyBar. Runs on SbarLua; its C helpers are built by Nix. Uses SF Pro + SF Mono (Homebrew `font-sf-pro` / `font-sf-mono`; the SF Symbols app, cask `sf-symbols`, is there for picking icons), and SwitchAudioSource. Clicking a space does nothing (it calls `yabai`, which isn't installed). The app-menu helper needs SketchyBar's Accessibility grant (below), and the Spotify widget its Automation permission for Spotify (macOS asks once)
    - SketchyBar comes from nixpkgs-unstable, with a local patch (`extra/sketchybar/layered-window-levels.patch`) that stops the bar dimming after a click on empty bar space
    - Autostarts via a launchd user agent (`launchd.user.agents.sketchybar`), the Nix equivalent of `brew services start sketchybar`
    - launchd runs a copy at `~/.local/libexec/sketchybar/sketchybar`, re-signed on every rebuild with a stable identity from agenix (`extra/sketchybar/signing.nix`), so privacy grants survive updates. Give any grant SketchyBar needs (e.g. Accessibility, for the app-menu helper or the calendar's Fantastical keystroke) to that path — in the file picker, ⌘⇧G and paste it — then `launchctl kickstart -k gui/$(id -u)/org.nixos.sketchybar`. A grant on a `/nix/store/…` path breaks on the next rebuild
    - To actually replace the native menu bar, hide it in System Settings → Control Center → Menu Bar (not Nix-managed)
- Top left hot corner: Show desktop
- Bottom left hot corner: Apps (Launchpad)

#### Secrets management (agenix)

- Env vars: `$NPM_FONT_AWESOME_TOKEN`, `$NPM_GITHUB_PACKAGES_TOKEN`.
- MailMate account config: `mailmate-sources`, `mailmate-identities`, `mailmate-submission`
  - Activation copies them into `~/Library/Application Support/MailMate/` **only if the file is absent**
- SketchyBar code-signing identity: `sketchybar-signing-identity` (a `.p12` of a self-signed codeSigning cert + key; the password is `nix-darwin`, and it's only meaningful inside agenix)

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
- poppler (PDF tools: `pdftotext`, `pdftoppm`, `pdfinfo`, etc. for Claude)

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