# Interface

- Touch ID for sudo (`macos.nix`)
- Window tiling (Rectangle)
    - Screen-edge gaps are Nix-managed (`rectangle.nix`): 8pt at the top so windows clear the 40pt SketchyBar, 76pt at the bottom for ExtraDock's docks. Quit and reopen Rectangle after `ns` for changes to apply
- Raycast (`other.nix`)
- SketchyBar ([More info](./sketchybar/README.md))
- Hot corners (`macos.nix`)
    - Top left: Show desktop
    - Bottom left: Apps (Launchpad)
