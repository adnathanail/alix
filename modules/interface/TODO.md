# Interface to-dos

Loose ends from setting up AeroSpace (workspaces, profiles and the SketchyBar
integration), left until it has been lived with for a while.

## Docs that are out of date

- [ ] **Rectangle: disabled but still documented as active.** Its line in
  `default.nix` is commented out, but it's still described in:
  - the interface README ("Window tiling")
  - `CLAUDE.md` (file map, per-tool notes, the Accessibility list)
  - `docs/FIRST_USE.md` step 3
  - the comment on the gaps in `aerospace.nix` ("Same values as Rectangle's")

  Once it's settled that AeroSpace replaces it, remove it properly (module,
  docs, maybe `graveyard.nix`), or turn it back on.
- [ ] **AeroSpace isn't in the setup docs.**
  - `docs/FIRST_USE.md` needs its Accessibility grant step.
  - `CLAUDE.md` needs a per-tool note covering what isn't obvious:
    - a key name AeroSpace doesn't recognise gets its binding silently
      dropped (`section` vs `sectionSign`)
    - a custom config replaces AeroSpace's defaults entirely
    - the upstream release is ad-hoc signed, so the Accessibility grant has to
      be given again after each version bump
    - there's no mode-change callback, so the mode-switching bindings trigger
      SketchyBar's event themselves

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
- [ ] **SketchyBar Safari button** (`sketchybar/config/items/safari.lua`): not
  yet clicked through (focus an existing profile window, or open a new one).

## Known quirks

- [ ] **Hint text is typed out by hand.** Both pills in
  `sketchybar/config/items/aerospace_mode.lua` repeat the key bindings. Update
  them when the bindings in `aerospace.nix` change, or generate them from Nix.
- [ ] **The SERVICE pill can get stuck** if service mode is left some other
  way than its own keys (e.g. `aerospace reload-config` from a shell).
  Entering and leaving service mode clears it.
- [ ] **ExtraDock and the bottom gap:** the 76pt bottom gap (AeroSpace, and
  Rectangle's) exists only for ExtraDock. If the per-workspace setup lets
  ExtraDock go, drop the gap and `extradock.nix` too.


Idea
- Have workspace 1 be non tiling with Rectangle?
- Maybe have them all like that, just use aerospace for sorting?