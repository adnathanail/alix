# Interface

- Touch ID for sudo (`macos.nix`)
- Window tiling (Rectangle)
    - All settings are Nix-managed (`rectangle.nix`) — change them there, not in the app, or `ns` will revert them. Quit and reopen Rectangle after `ns` for changes to apply
    - Screen-edge gaps: 8pt at the top so windows clear the 40pt SketchyBar, 76pt at the bottom for ExtraDock's docks
    - *First use on a fresh machine*: tick **Launch on login** once in the app (the Nix setting only ticks the box)
- AeroSpace tiling window manager (`aerospace.nix`)
    - Config is Nix-managed — edit `aerospace.nix`, not `~/.aerospace.toml` (it's ignored)
    - Keyboard-driven — see [AeroSpace shortcuts](#aerospace-shortcuts) below
    - Pinned apps (`on-window-detected` in `aerospace.nix`): Spotify → workspace 9
    - *First use / after a version bump*: grant Accessibility to AeroSpace in System Settings → Privacy & Security
- Raycast (`other.nix`)
- SketchyBar ([More info](./sketchybar/README.md))
- Hot corners (`macos.nix`)
    - Top left: Show desktop
    - Bottom left: Apps (Launchpad)

## AeroSpace shortcuts

Bindings are declared in `aerospace.nix` (⌥ = Option). Each workspace is a tree of containers; a
container lays out its windows either **tiles** (all visible, sharing the space) or **accordion**
(overlapping, the focused one fills the space), horizontally or vertically.

### Main mode

| Keys | Does |
| --- | --- |
| ⌥H / ⌥J / ⌥K / ⌥L | Focus the window left / down / up / right |
| ⌥⇧H / ⌥⇧J / ⌥⇧K / ⌥⇧L | Move the focused window left / down / up / right |
| ⌥/ | Tiles layout; press again to flip horizontal ↔ vertical |
| ⌥, | Accordion layout; press again to flip horizontal ↔ vertical |
| ⌥- / ⌥= | Shrink / grow the focused window |
| ⌥1 – ⌥9 | Switch to workspace 1–9 |
| ⌥⇧1 – ⌥⇧9 | Send the focused window to workspace 1–9 |
| ⌥Tab | Back to the previous workspace |
| ⌥⇧Tab | Move the current workspace to the next monitor |
| ⌥⇧; | Enter service mode |
| ⌥` | Swap SketchyBar between workspaces and the app's menus |

### Service mode

Press ⌥⇧; then one key — each runs its command and returns to main mode. SketchyBar shows a red **SERVICE** pill while it's active.

| Key | Does |
| --- | --- |
| F | Toggle the focused window between floating and tiled |
| R | Reset the workspace layout (flatten the tree) |
| ⌥⇧H / ⌥⇧J / ⌥⇧K / ⌥⇧L | Join the focused window with its neighbour into a new nested container |
| Esc | Reload the config |

### CLI

- `aerospace list-windows --all` — every window with its app ID and title (what workspace rules match on)
- `aerospace list-workspaces --all`
