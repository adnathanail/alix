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
    # Cmd+Shift+P command palette, …). Cmd only reaches Fresh, via the Kitty
    # keyboard protocol, for combinations Ghostty doesn't bind itself;
    # Ghostty keeps Cmd+C/V/A/Z/Q/N/W/F/G/D/[/] and Cmd+Shift+P.
    active_keybinding_map = "macos-gui";
    # Upgrade check (and the anonymous telemetry sent with it). Updates come
    # through nixpkgs instead.
    check_for_updates = false;
    # Wave-animation screensaver after `screensaver_idle_minutes` (default 5)
    # with no input.
    editor.screensaver_enabled = true;
  };
}
