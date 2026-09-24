# Setting up a new Mac

A first attempt — untested end to end, so expect to adjust it. The config comes up in four
stages, **core → secrets → interface → apps**, each depending only on the ones before. For each
stage, uncomment its line in the `modules` list in `flake.nix` and rebuild.

Don't run a partial config on a Mac that already has everything installed:
`cleanup = "zap"` uninstalls (and deletes the data of) every cask the config doesn't list.

## 0. Prerequisites

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

## 1. Core — terminal, editor, Claude Code, 1Password

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

## 2. Secrets — env-var tokens, git commit signing

Uncomment `modules/secrets`, then `ns`.

Check it worked: `ls /run/agenix/` lists the secrets, and in a new shell
`echo $NPM_FONT_AWESOME_TOKEN` is non-empty. Commits are now signed through 1Password (a
biometric prompt per commit); the public key is already on GitHub as a signing key.

Switch the repo's remote to SSH now that 1Password's agent holds the key:
```bash
git -C ~/.config/nix-darwin remote set-url origin git@github.com:adnathanail/alix.git
```

## 3. Interface — SketchyBar, Dock, Rectangle, Raycast

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

See [modules/interface/README.md](../modules/interface/README.md).

## 4. Apps — everything else

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
   ask (Screen Recording for Slack and Pika, Calendar/Contacts/Mic/Camera per app).

Every module is now enabled; `flake.nix` should match the repo again (`git diff` is empty).
