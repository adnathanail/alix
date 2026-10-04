# Setting up a new Mac

Four stage config: **core → secrets → interface → apps**; each depends only on the ones before.

For each stage, uncomment its line in the `modules` list in `flake.nix` and rebuild.

Don't run a partial config on a Mac that already has everything installed:
`cleanup = "zap"` uninstalls (and deletes the data of) every cask the config doesn't list.

## -1. On the previous Mac

Record every repo's local branches in clonager's config, so step 4 can recreate them here:
```bash
cg config airlift
```

- It refuses until the laptop is tidy (everything committed and pushed, nothing for `cg prune --forge` to do)

Commit and push the config change in `~/.config/nix-private`.

- Don't run `cg config tidy` on the old Mac afterwards: its branches still exist, so it would drop them from the config.

## 0. Prerequisites

When setting up the laptop, make sure the username is `adnathanail`

[Install Lix](https://lix.systems/install/#on-any-other-linuxmacos-system)
```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
# Enable flakes? Y
# Proceed? Y
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

## 1. Core — terminal, editor, Claude Code, 1Password, macOS settings

Bootstrap `nix-darwin`

- (The branch must match the `nix-darwin` input in `flake.nix`, and the `#Alexs-MacBook-Pro` must match `hostname` there — a new Mac's own hostname may differ)

```bash
sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake ~/.config/nix-darwin#Alexs-MacBook-Pro
```

- This asks for `sudo` to take ownership of `/opt/homebrew`. Open a new terminal (Ghostty) and `ns` works from here on.

- Installs Ghostty, GitButler, VS Code, Claude Code, 1Password + `op`, git, zsh, python/uv/node, and sets the Dock, hot corners, menu-bar clock and Touch ID for sudo (`modules/core/macos.nix`).

Then:
1. Sign into 1Password. In Settings → Developer, turn on **Integrate with 1Password CLI** and
   **Use the SSH agent**.
2. `nix-restore-age-key` — pulls the age key from 1Password to `~/.config/age/keys.txt`.
3. Sign into Claude Code (`claude`), VS Code, GitButler.
4. Set Safari homepage `https://newtab.adnathanail.dev`

## 2. Secrets — env-var tokens, git commit signing

Uncomment `modules/secrets`, then `ns`.

Check it worked:
```bash
ls /run/agenix/  # lists the secrets
echo $NPM_FONT_AWESOME_TOKEN  # check env var (in new shell)
```
- Commits are now signed through 1Password (a biometric prompt per commit); the public key is already on GitHub as a signing key.

Switch the repo's remote to SSH now that 1Password's agent holds the key:
```bash
git -C ~/.config/nix-darwin remote set-url origin git@github.com:adnathanail/alix.git
```

Clone the private config repo (MailMate accounts, clonager's config). (Stage 4 reads it):
```bash
git clone git@github.com:adnathanail/nix-private.git ~/.config/nix-private
```

## 3. Interface — SketchyBar, AeroSpace, ExtraDock, Raycast

Uncomment `modules/interface`, then `ns`.

Then:
1. Hammerspoon: open it once so it registers its login item, then grant Accessibility.
2. Log out and back in, so turning off macOS's own swipe between Spaces takes effect (aerospace-swipe replaces it).
3. Raycast: work through onboarding (let it take ⌥Space from Spotlight).
4. ExtraDock: set the licence (Settings → License), then import `~/.config/extradock/ExtraDock.extradock5backup` with **Import Backup** (not Import Settings; ⌘⇧G in the file picker to type the path).
   That's the only manual import: it also turns on **Allow AI assistants**, after which every `ns` keeps ExtraDock in step through `extradock-apply`. Check with `extradock-apply --dry-run` (should say it already matches).
5. System Settings → Privacy & Security:
    - **Device Control and Data Access**:
         - AeroSpace, aerospace-swipe: Should prompt on `ns`
         - SketchyBar: Click the Apple icon and it should ask
         - Hammerspoon: Should prompt after opening
         - Raycast: Should ask during setup
         - ExtraDock: Should ask during setup
    - **Input Monitoring**: Raycast (should during setup)

See [modules/interface/README.md](../modules/interface/README.md).

## 4. Apps — everything else

Sign into the Mac App Store first (App Store app → Sign In): this stage installs App Store
apps, and a failed install aborts the whole `ns`.

Uncomment `modules/apps`, then `ns`. Xcode alone is ~15 GB, so the first run is slow.

Then:
1. `sudo xcodebuild -license accept` and
   `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
2. Safari:
   - Safari → Settings → Extensions: enable 1Password and Save to Raindrop.io.
   - Hand password autofill to 1Password: Safari → Settings → AutoFill, untick **User names and passwords**
   - System Settings → General → AutoFill & Passwords, untick **Passwords** under AutoFill From (leave 1Password ticked).
3. MailMate: sign into each account once (OAuth in the browser)
4. PyCharm: select the `ALix keymap`.
5. Sign into the rest (Slack, Todoist, Fantastical, …) and grant per-app permissions as they ask (Screen Recording for Slack and Pika, Calendar/Contacts/Mic/Camera per app).
6. Clone the repos from clonager's config (as airlifted in step -1). `cg clone` only prints
   the git commands, so review them, then run them:
   ```bash
   cg clone        # review
   cg clone | sh
   ```
   Once the branches exist, `cg config tidy` removes them from the config.

Every module is now enabled; `flake.nix` should match the repo again (`git diff` is empty).
