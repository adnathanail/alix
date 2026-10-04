# Interface

Loose ends to deal with later: [TODO.md](./TODO.md)

- AeroSpace tiling window manager (`aerospace.nix`)
    - Config is Nix-managed — edit `aerospace.nix`, not `~/.aerospace.toml` (it's ignored)
    - Screen-edge gaps: 8pt at the top so windows clear the 40pt SketchyBar, 76pt at the bottom for ExtraDock's docks
    - Keyboard-driven — see [AeroSpace shortcuts](#aerospace-shortcuts) below
    - Pinned apps (`on-window-detected` in `aerospace.nix`): GitButler → 0 (the only thing allowed there, bar 1Password so its commit-signing prompts stay put: anything else opened on 0 goes to 1, and you with it), MailMate → 8, Spotify → 9, Safari and VS Code windows that match no profile but were opened on a profile's workspace → 1 (and any Safari or VS Code window is re-checked for 10s after opening, in case a profile's title appears late)
    - Profiles (`profiles.nix`): each has a name, workspace, colour and optional apps. Its apps, Safari windows in the Safari profile of the same name, and VS Code windows titled `<name> - …` go to its workspace, and SketchyBar colours that workspace's pill. Currently Fermioniq (4, + Slack) and ASAC (5)
        - SketchyBar's Safari button (left of the widgets) takes the current workspace's profile colour; clicking it focuses that profile's Safari window, or opens one (Personal on workspaces without a profile)
        - To label a VS Code project with a profile, set its window title in the project's `.vscode/settings.json` (the rest after the prefix is VS Code's default title):
          ```json
          "window.title": "Fermioniq - ${activeEditorShort}${separator}${rootName}${separator}${profileName}"
          ```
    - *First use / after a version bump*: grant Accessibility to AeroSpace in System Settings → Privacy & Security
    - Four-finger swipe left / right moves to the next / previous workspace with windows on it, like swiping between Spaces (`aerospace-swipe.nix`, using [aerospace-swipe](https://github.com/acsandmann/aerospace-swipe)). macOS's own three- and four-finger swipe between Spaces is turned off so they don't both fire; you may need to log out and back in for that
        - Settings are `config.json` in `aerospace-swipe.nix`; after changing them, restart it with `launchctl kickstart -k gui/$(id -u)/org.nixos.aerospace-swipe`
        - *First use*: it asks for Accessibility; grant it in System Settings → Privacy & Security. launchd runs a re-signed copy at `~/.local/libexec/aerospace-swipe/aerospace-swipe` (like SketchyBar's), so the grant survives rebuilds. Logs are in `~/Library/Logs/aerospace-swipe*.log`
- Fn+2 types €, Fn+3 types # — the characters ⌥2 / ⌥3 would type, which AeroSpace's bindings take over (Hammerspoon, `hammerspoon/`)
    - Config is Nix-managed — edit `hammerspoon/init.lua` (add more keys to `fnChars`), not `~/.config/hammerspoon`. Hammerspoon reloads it itself after `ns`
    - *First use*: open Hammerspoon once and grant it Accessibility in System Settings → Privacy & Security (it's a signed app, so this survives updates)
- Unread notifications: red Slack and/or MailMate icons in SketchyBar (left of the Safari button), whichever have something unread, with one combined count; hidden when there's nothing. Click for a native menu of each app's count; choosing one focuses that app (`hammerspoon/notifications.lua` reads the counts, `sketchybar/config/items/notifications.lua` draws the item)
    - Slack's count is its Dock badge. MailMate draws its own Dock icon, so its count comes from MailMate's menu-bar counter instead. That only works with unread as the sole menu-bar counter, so MailMate's counters are declared in `../apps/mailmate.nix` — change them there, not in MailMate's settings
- ExtraDock's docks (Productivity, Comms, Running apps) and settings (`extradock-config.nix`)
    - Edit `extradock-config.nix`, `ns`, then import `~/.config/extradock/ExtraDock.extradock5backup` with ExtraDock's **Import Backup** — not Import Settings, which only reads a bare settings JSON (⌘⇧G in the file picker to type the path). In-app changes aren't saved back to the repo
    - The Running apps widget hides every app pinned in another dock; that list is worked out from the docks, not written by hand
- Raycast (`other.nix`)
- SketchyBar ([More info](./sketchybar/README.md))

## AeroSpace shortcuts

Bindings are declared in `aerospace.nix` (⌥ = Option). Hold ⌥ on its own for a moment and SketchyBar shows a blue pill with the main-mode hints. Each workspace is a tree of containers; a
container lays out its windows either **tiles** (all visible, sharing the space) or **accordion**
(overlapping, the focused one fills the space), horizontally or vertically. Workspaces start as accordions.

### Main mode

| Keys | Does |
| --- | --- |
| ⌥H / ⌥J / ⌥K / ⌥L | Focus the window left / down / up / right |
| ⌥⇧H / ⌥⇧J / ⌥⇧K / ⌥⇧L | Move the focused window left / down / up / right |
| ⌥/ | Tiles layout; press again to flip horizontal ↔ vertical |
| ⌥, | Accordion layout; press again to flip horizontal ↔ vertical |
| ⌥- / ⌥= | Shrink / grow the focused window |
| ⌥§, ⌥1 – ⌥9 | Switch to workspace 0–9 |
| ⌥⇧§, ⌥⇧1 – ⌥⇧9 | Send the focused window to workspace 0–9 |
| ⌥Tab | Back to the previous workspace |
| ⌥⇧Tab | Move the current workspace to the next monitor |
| ⌥⇧; | Enter service mode |
| ⌥` | Cycle SketchyBar through workspaces → the app's menus → the native macOS menu bar (as clicking its switch does), and back to workspaces |

### Service mode

Press ⌥⇧; then one key — each runs its command and returns to main mode. SketchyBar shows a red **SERVICE** pill while it's active.

| Key | Does |
| --- | --- |
| F | Toggle the focused window between floating and tiled |
| R | Reset the workspace layout (flatten the tree) |
| S | Sort: send every window that has a rule back to its workspace (also `aerospace-sort` in a shell) |
| ⌥⇧H / ⌥⇧J / ⌥⇧K / ⌥⇧L | Join the focused window with its neighbour into a new nested container |
| Esc | Reload the config |

### CLI

- `aerospace list-windows --all` — every window with its app ID and title (what workspace rules match on)
- `aerospace list-workspaces --all`
