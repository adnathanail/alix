{ pkgs, ... }: {
  # Fresh (`fresh`), a terminal text editor. From nixpkgs master, like
  # claude-code, so a new release lands as soon as nixpkgs merges it.
  # nixpkgs' wrapper passes `--no-upgrade-check`.
  home.packages = [ pkgs.master.fresh-editor ];

  # User config. Nix-owned, so Fresh's Settings UI can't save to it: change
  # it here instead.
  xdg.configFile."fresh/config.json".text = builtins.toJSON {
    version = 1;
    # macOS keymap plus standard Cmd shortcuts (Cmd+S save, Cmd+P quick open,
    # Cmd+Shift+P command palette, …). Cmd only reaches Fresh for
    # combinations the terminal doesn't bind itself. Rex keeps
    # Cmd+C/V/X/A/Z/Q/W/T/H/K/R/M/,/./slash/0/+/- and Cmd+Shift+N/G/W/Z/P from
    # its menus, plus Cmd+B/O/G from its init.lua (modules/apps/rex.nix), so
    # Fresh still gets Cmd+S/P/F/D/N/[/] there but loses Cmd+Shift+P. Ghostty
    # keeps a different set, including Cmd+N/F/G/D/[/] and Cmd+Shift+P.
    active_keybinding_map = "macos-gui";
    # PyCharm's macOS shortcuts: Cmd+Shift+O finds a file by name (Go to
    # File), Cmd+Shift+A finds a command (Find Action), Cmd+Shift+F searches
    # the text of every file in the project (Find in Files — Fresh's Live
    # Grep, also on Alt+/). Cmd+Shift+O replaces the keymap's Go to Symbol,
    # still reachable as Cmd+P then @. Rex binds none of these, so they reach
    # Fresh there; Ghostty keeps Cmd+Shift+F for closing its own search bar.
    # (Both terminals keep Cmd+Shift+P for their own command palettes.)
    # Files and commands share one picker, told apart by a typed prefix (none
    # for files, `>` for commands); `quick_open` starts it with `>` already
    # typed, so files need `quick_open_files`.
    keybindings = [
      { key = "o"; modifiers = [ "super" "shift" ]; action = "quick_open_files"; args = { }; when = "global"; }
      { key = "a"; modifiers = [ "super" "shift" ]; action = "command_palette"; args = { }; when = "global"; }
      { key = "f"; modifiers = [ "super" "shift" ]; action = "open_live_grep"; args = { }; when = "normal"; }
    ];
    # Upgrade check (and the anonymous telemetry sent with it). Updates come
    # through nixpkgs instead.
    check_for_updates = false;
    # Wave-animation screensaver after `screensaver_idle_minutes` (default 5)
    # with no input.
    editor.screensaver_enabled = true;
  };
}
