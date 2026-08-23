# CLAUDE.md

Context for working on this nix-darwin configuration. Read this before making changes.

## Committing

Sometimes this repository is managed with GitButler.
Check whether you are on the `gitbutler/workspace` branch; if so, use the `but` CLI to interact with it.
Make changes in new commits, as opposed to modifying existing commits, unless explicitly told to.

**Do not add attributions to yourself in commit messages**

## What this is

Declarative macOS config for a single MacBook: a Nix flake with **nix-darwin** + **Home Manager**,
living at `~/.config/nix-darwin/`.

- **User:** `adnathanail` · **Host / darwinConfiguration attr:** `Alexs-MacBook-Pro` ·
  **Platform:** `aarch64-darwin`
- **Nix implementation:** **Lix** (a fork — *not* upstream Nix), installed via the Lix installer.
  Harmless `using 'or' as an identifier is deprecated` warnings during eval are nixpkgs noise.

### File map

| Path | Owns |
| --- | --- |
| `flake.nix` | inputs, unstable overlay, `system.defaults`, Homebrew casks/brews, nix-homebrew + HM wiring |
| `home.nix` | Home Manager user config (packages, git, zsh, VS Code, PyCharm keymap, Ghostty config) |
| `agenix.nix` | shared agenix machinery only — module, CLI, `age.identityPaths`, `nix-restore-age-key`. Declares **no** secrets |
| `extra/envvars.nix` | secrets exposed as shell env vars: their `age.secrets` blocks, the `nix-secrets.env` writer, the zsh `source` line |
| `extra/mailmate.nix` | everything MailMate: the cask, the account-config secrets, the provision-once activation step |
| `extra/appdev.nix`, `extra/macapps.nix`, `extra/safariexts.nix` | darwin modules, each adding to `homebrew.masApps` (they merge); deliberately independent of each other |
| `extra/rocq.nix`, `extra/eleventy.nix`, `extra/nx.nix`, `extra/uvtools.nix` | optional HM feature modules, imported from `home.nix` — comment out a line to drop the feature |
| `secrets/*.age`, `secrets/secrets.nix` | encrypted secrets + their recipients |
| `pycharm/custom-keymap.xml`, `nx/` | files consumed by the modules above |

## Rules

- **DO NOT REBUILD — ask the user to do it.** Activation needs root. The command is `ns`
  (alias for `nix-switch`, itself `sudo darwin-rebuild switch --flake ~/.config/nix-darwin`).
- **Add new software/tools/config to `README.md`.**
- **Never use a tool's self-updater** — the store is read-only. Update via `nix flake update` +
  rebuild, or the Homebrew cask refresh on rebuild. Disable in-app updaters where exposed.

## Key architectural decisions

### `nix.enable = false` — do not change
The Lix installer owns the Nix install, its daemon, and `/etc/nix/nix.conf`; nix-darwin managing
those too collides (`error: Unexpected files in /etc`).

- Do **not** hand `/etc/nix/nix.conf` to nix-darwin — dueling daemons.
- All `nix.*` options (`nix.settings.*`, Linux builder, …) are therefore **unavailable**. Extra
  Nix settings (substituters, trusted-users, caches) go in `/etc/nix/nix.custom.conf`, which the
  Lix-generated `nix.conf` already `!include`s.
- Flakes + `nix-command` are already enabled globally by the installer.

### Stable pins: nixpkgs 26.05, HM `release-26.05`, nix-darwin `nix-darwin-26.05`
**The HM branch must match the nixpkgs branch.** HM `master` against stable nixpkgs fails to eval
(`lib/services/...: No such file or directory`) because master expects *unstable's* `lib`. If
nixpkgs moves to unstable, move HM to `master` in the same commit. HM release branches get bug
fixes but rarely new modules — a brand-new HM module may exist only on `master`.

### Selective unstable overlay
`unstableOverlay` in `flake.nix` pulls **specific** packages from `nixpkgs-unstable`, leaving
everything else on stable: `claude-code`, `prek`, `vscode`, `jetbrains.pycharm`. `jetbrains` is
merged (`prev.jetbrains // { … }`) so other JetBrains IDEs still come from stable. Reuse this
pattern for anything that needs to be fresher than the pin.

`nixpkgs.config.allowUnfree = true` is required for `claude-code`, `vscode`, `jetbrains.pycharm`.

### Home Manager as a nix-darwin module
`useGlobalPkgs = true` (so HM gets the system `pkgs` **with overlays applied** — this is how the
unstable overlay and the VS Code extension set reach HM), `useUserPackages = true`,
`backupFileExtension = "hm-backup"` (HM moves pre-existing non-Nix files aside instead of
refusing to activate). HM apps land in `~/Applications/Home Manager Apps/`; Spotlight and
`open -a` still find them.

### `nix-homebrew` for signed / path-locked GUI apps
`nix-homebrew` installs and pins Homebrew itself; `homebrew.*` in `flake.nix` declares the casks.
First activation prompts for `sudo` to take ownership of `/opt/homebrew`.

Homebrew is used **only** for apps that path-check `/Applications` or need an intact Apple
designated-requirement signature (Nix's wrap step invalidates it, and HM installs to
`~/Applications/…`). Everything else stays on Nix.

- `onActivation.cleanup = "zap"` — **anything not declared in `homebrew.casks` / `brews` /
  `masApps` gets uninstalled on rebuild.** This is why `mas` is pinned in `brews`.
- `onActivation.upgrade = true`, `autoUpdate = false` (activation stays deterministic; bump
  Homebrew itself with `nix flake update nix-homebrew`), `enableRosetta = false`.

### Secrets via agenix
**Secrets live with their users, not in one secrets file.** `agenix.nix` holds only the
shared machinery — the agenix module, the `agenix` CLI, `age.identityPaths`, and
`nix-restore-age-key` — and declares no `age.secrets.<name>` blocks itself. Each consuming module
owns its own: `extra/envvars.nix` for the shell tokens, `extra/mailmate.nix` for the MailMate
account config. A new secret-using feature gets its own `extra/<feature>.nix` rather than an
entry in a shared file.

This works because `age.secrets`, `homebrew.casks` and `system.activationScripts.<name>.text`
all merge across modules rather than conflicting.

Encrypted secrets live in `secrets/*.age` (safe to commit), recipients in `secrets/secrets.nix`.
Activation decrypts them to `/run/agenix/<name>` using the age identity at
`~/.config/age/keys.txt`, then writes shell-facing tokens into `~/.config/nix-secrets.env` as
bash-`%q`-quoted `export` lines (rewritten every `ns`); zsh sources that file.

Adding an env-var secret = two edits in `extra/envvars.nix` (`age.secrets.<name>` block, a
`write <VAR> /run/agenix/<name>` line in the activation script) plus an entry in
`secrets/secrets.nix` and the encrypted file itself. Operator steps are in the README.
`secrets/secrets.nix` is read by the `agenix` **CLI**, not the module system, so it stays a
single flat map of filename → publicKeys and can't be split up per-feature.

Not every secret is a shell env var — `mailmate-*` are files copied into place by the activation
script instead (see *MailMate* below).

**Encrypting non-interactively:** `agenix -e` **ignores `$EDITOR` when stdin isn't a TTY** and
substitutes `cp -- /dev/stdin`, so pipe the content in — `agenix -e <name>.age -i
~/.config/age/keys.txt < plaintext`. Setting `EDITOR="cp src"` silently yields a **200-byte
empty** secret that only fails at activation. `agenix` also can't find the age identity on its
own (it looks for `~/.ssh/id_*`), so pass `-i ~/.config/age/keys.txt` for both `-e` and `-d`.
Sanity-check any new secret by decrypting it and diffing against the source.

A dedicated age key (not the SSH key) means activation never hits a passphrase prompt. The
private key is **not** Nix-managed; it's backed up to 1Password as document `nix-darwin age key`
(Private vault) and restored on a fresh machine with `nix-restore-age-key`. After rotating,
re-run `op document edit "nix-darwin age key" ~/.config/age/keys.txt`.

### System defaults
`system.defaults` in `flake.nix` covers the Dock (no recents, hot corners, pinned apps),
menu-bar clock, Control Center, Touch ID for sudo
(`security.pam.services.sudo_local.touchIdAuth` — writes `/etc/pam.d/sudo_local`, survives macOS
updates, doesn't work in tmux without `pam_reattach`), and `CustomUserPreferences` for the `pbs`
services hotkey and Microsoft's domains. Note some domains are TCC-protected and can't be set
from the activation script — those stay manual toggles.

## Per-tool notes

Only the surprising bits. The full software list and first-use steps live in `README.md`.
Per-app state (sign-ins, caches, prefs, licences) lives under `~/Library/…` and is **not**
Nix-managed unless noted.

- **Claude Code** *(Nix, unstable overlay)* — `programs.claude-code`. Self-updater off via
  `home.sessionVariables.DISABLE_AUTOUPDATER = "1"`. The `claude symlink points to an invalid
  binary` warning is a harmless false positive (Nix wraps it as a script). The VS Code extension
  and PyCharm plugin update independently of the CLI.
- **VS Code** *(Nix, unstable overlay, Nix-managed config + extensions)* — `programs.vscode`,
  `profiles.default`. Only the `vscode` attr is on unstable; `pkgs.vscode-extensions` still comes
  from stable, which is fine (a newer editor runs older extensions).
  `settings.json` is Nix-owned: edit `userSettings` in `home.nix`, not in-app.
  `mutableExtensionsDir = false` means HM fully owns `~/.vscode/extensions`, so extensions can
  **only** be added by editing `home.nix` (or `extra/rocq.nix` / `extra/eleventy.nix`) and
  rebuilding. Prefer `pkgs.vscode-extensions.<publisher>.<name>`; otherwise
  `pkgs.vscode-utils.extensionFromVscodeMarketplace` with publisher, name, version, and hash
  (bump version + hash together). The first eval after adding the extension set is slow.
- **PyCharm Professional** *(Nix, unstable overlay)* — lands at
  `~/Applications/Home Manager Apps/PyCharm.app`. The keymap at `pycharm/custom-keymap.xml`
  (named "ALix keymap" in-app) is symlinked into
  `~/Library/Application Support/JetBrains/PyCharm2026.2/keymaps/` by `home.nix`. Edits inside
  PyCharm fail silently (read-only target) — edit the XML in the repo. **The destination path is
  version-pinned:** after a minor-version bump (`2026.2` → `2026.3`) update it in `home.nix` or
  the keymap lands in an unused directory.
- **Ghostty** *(Homebrew, Nix-managed config)* — `pkgs.ghostty` on Darwin is fragile (Swift/Xcode
  toolchain). Config at `~/.config/ghostty/config` is Nix-owned via `xdg.configFile`; it sets
  `auto-update = off` to suppress Sparkle's prompt. In-app config edits don't persist. If the
  config grows, consider the HM `programs.ghostty` module (check it's on `release-26.05` first).
- **prek** *(Nix, unstable overlay)* — Rust reimplementation of `pre-commit`; on unstable because
  stable lags this fast-moving 0.x tool.
- **nx** *(Nix, built locally)* — not in nixpkgs; built via `buildNpmPackage` from the wrapper
  project at `nx/`. See *Routine maintenance*.
- **git** *(Nix)* — `programs.git` owns identity and `~/.gitconfig`. Installing git via Nix
  sidesteps Apple's Command Line Tools prompt; CLT is still needed for build systems that
  hardcode `/usr/bin/git` or need Apple SDK headers.
- **1Password + CLI** *(Homebrew)* — `pkgs._1password-gui` refuses to run outside `/Applications`,
  and the desktop ↔ CLI biometric handshake verifies AgileBits' signature on `op`, which Nix's
  wrap step invalidates. Homebrew ships both signed binaries as-is.
- **OrbStack** *(Homebrew)* — installs a privileged helper and CLI shims (`docker`,
  `docker compose`, `orb`, `orbctl`) into `/usr/local/bin`. **Do not also install `pkgs.docker` /
  `pkgs.docker-compose`** — PATH conflicts.
- **Raycast** *(Homebrew)* — Login Items helper + system-wide hotkey; default ⌥Space collides
  with Spotlight (onboarding offers to disable it).
- **Bartender** *(Homebrew)* — without Screen Recording, hidden icons render blank; without
  Accessibility, clicks land on the wrong items.
- **Microsoft Outlook / Office** *(Homebrew, Nix-managed prefs)* — prefs are set through
  `system.defaults.CustomUserPreferences` on `com.microsoft.Outlook` and `com.microsoft.office`.
  This works for a sandboxed app because Microsoft documents `defaults write` as the supported
  mechanism (CFPreferences redirects into the container plist). Currently:
  `AutomaticallyDownloadExternalContent = false`, `FocusedInbox = false`,
  `DiagnosticDataTypePreference = "BasicTelemetry"` (`ZeroTelemetry` is enterprise-only). Add
  keys here, not in-app — see Microsoft Learn, *Set preferences for Outlook for Mac*. Microsoft
  AutoUpdate is disabled via `"com.microsoft.autoupdate2".HowToCheck = "Manual"` so updates flow
  through the cask refresh.
- **MailMate** *(Homebrew `mailmate@beta`; account config via agenix)* — mechanics are
  commented in `extra/mailmate.nix`; what follows is only what isn't.
  **Accounts are *not* in the defaults domain** — they're three NeXTSTEP-format ASCII plists
  under `~/Library/Application Support/MailMate/` (`Sources.plist` IMAP, `Submission.plist`
  SMTP, `Identities.plist` from-addresses) using MailMate's own `:true`/`:false` encoding, so
  store them verbatim rather than generating them from Nix attrs. `Mailboxes.plist` is
  app-owned; leave it out. Settings *are* ordinary defaults (`com.freron.MailMate` is
  non-sandboxed); quit MailMate before `ns` if any get declared, since it flushes prefs on quit
  over activation's writes.
  **Outlook.com / Hotmail: both hosts must be `*.office365.com`, and MailMate's own setup wizard
  gets this wrong.** Working pair is `outlook.office365.com:993` + `smtp.office365.com:587`; the
  wizard pairs the correct IMAP host with `smtp-mail.outlook.com:587`. Provider detection is
  **hostname-based** (`Office365 not detected` in the binary; the recognised set is
  `outlook.office365.com`, `smtp.office365.com`, `mail.office365.com`), so the *consumer* host
  `smtp-mail.outlook.com` fails detection, never enables OAuth, and falls back to basic auth —
  which Microsoft disabled for Outlook.com in Sept 2024. Symptoms in the order they appear:
  `LOGINDISABLED (no plain text login allowed)` on IMAP → `535 5.7.139 … basic authentication is
  disabled` on SMTP → `error code -25300` once the cached password is deleted. Setting
  `"oauth2" = :true;` in `Submission.plist` is **not** sufficient alone — the hostname drives
  detection. A stale SMTP password in the Keychain also shadows OAuth; clear it with
  `security delete-internet-password -s smtp-mail.outlook.com -a <address>`.
- **Mac App Store apps** *(via `mas`)* — Apple ships Xcode, Office, iMovie etc. only through the
  App Store. Adding one is a one-line entry in whichever `extra/` file fits the category; find
  IDs with `mas search <name>`. **Requires being signed into the App Store first** — modern `mas`
  can't sign in from the CLI, and activation fails with `Not signed in`. Xcode's first install
  downloads ~15 GB. Afterwards run `sudo xcodebuild -license accept` and
  `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- **Rectangle** *(Nix)* — fetched from the official `.dmg`. Prefs aren't Nix-managed; could be
  promoted via `system.defaults.CustomUserPreferences."com.knollsoft.Rectangle"`.

Manual, non-Nix setup a fresh machine still needs: App Store sign-in (**before** the first `ns`),
per-app sign-ins/licences, and System Settings → Privacy & Security grants — Accessibility
(Rectangle, Raycast, Bartender), Screen Recording (Bartender, Slack), Input Monitoring (Raycast),
Notifications/Calendar/Contacts/Mic/Camera per app.

## Routine maintenance

- `nix flake update <input>` (e.g. `nixpkgs-unstable`, `nix-homebrew`) or `nix flake update` for
  everything — then ask the user to rebuild. Casks refresh on every rebuild.
- After a PyCharm minor-version bump: update the version-pinned keymap path in `home.nix`.
- Bumping `nx` (flake updates don't touch it): edit `nx/package.json`, then
  ```bash
  (cd nx && npm install --package-lock-only --ignore-scripts)
  nix run nixpkgs#prefetch-npm-deps -- nx/package-lock.json
  ```
  Paste the printed `sha256-…` into `npmDepsHash` in `extra/nx.nix` and bump `version` there to
  match. Commit `nx/package.json`, `nx/package-lock.json`, `extra/nx.nix` together.
