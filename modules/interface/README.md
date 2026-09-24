# Interface

- Touch ID for sudo (`macos.nix`)
- Window tiling (Rectangle)
    - All settings are Nix-managed (`rectangle.nix`) — change them there, not in the app, or `ns` will revert them. Quit and reopen Rectangle after `ns` for changes to apply
    - Screen-edge gaps: 8pt at the top so windows clear the 40pt SketchyBar, 76pt at the bottom for ExtraDock's docks
    - *First use on a fresh machine*: tick **Launch on login** once in the app (the Nix setting only ticks the box)
- Raycast (`other.nix`)
- SketchyBar ([More info](./sketchybar/README.md))
- Hot corners (`macos.nix`)
    - Top left: Show desktop
    - Bottom left: Apps (Launchpad)
