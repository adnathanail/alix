# Interface to-dos

Loose ends from setting up AeroSpace (workspaces, profiles and the SketchyBar
integration), left until it has been lived with for a while.

## To confirm in real use

- [ ] **VS Code late-title watcher** (`titleWatch` in `aerospace.nix`): only
  tested against a fake `aerospace`. It relies on AeroSpace telling it which
  window just opened (`AEROSPACE_WINDOW_ID`), falling back to the focused
  window if not. Watch for a new Fermioniq or ASAC project that stays on 1.
- [ ] **Focus at startup:** after `ns` or a login, with a Fermioniq or ASAC VS
  Code project open, you might start on 4 or 5 instead of 1. The profile rules
  take focus along with the window, and AeroSpace's switch to 1 may run before
  them. If so, make those rules follow only when `during-aerospace-startup =
  false`.

## Known quirks

- [ ] **Hint text is typed out by hand.** Both pills in
  `sketchybar/config/items/aerospace_mode.lua` repeat the key bindings. Update
  them when the bindings in `aerospace.nix` change, or generate them from Nix.
- [ ] **The SERVICE pill can get stuck** if service mode is left some other
  way than its own keys (e.g. `aerospace reload-config` from a shell).
  Entering and leaving service mode clears it.
- [ ] **ExtraDock and the bottom gap:** AeroSpace's 76pt bottom gap exists
  only for ExtraDock. If the per-workspace setup lets
  ExtraDock go, drop the gap and `extradock.nix` too.

## Ideas

- Have workspace 1 be non-tiling, with Rectangle (now in `graveyard.nix`)
  for snapping?
- Maybe have them all like that, and just use AeroSpace for sorting?
