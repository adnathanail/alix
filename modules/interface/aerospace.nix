# AeroSpace — i3-style tiling window manager with its own virtual
# workspaces (no native Spaces, no SIP changes). nix-darwin's module writes
# the settings below to a store-path aerospace.toml and runs the app from a
# launchd user agent, so AeroSpace's own start-at-login stays off.
#
# A custom config replaces AeroSpace's built-in one wholesale, so the key
# bindings below are its defaults re-declared (minus the alt-<letter>
# workspaces, which clobber ⌥-typed characters, and service mode's
# close-all-windows-but-current on backspace). Anything not listed is
# unbound.
#
# The upstream release is ad-hoc signed, so its Accessibility grant is
# pinned to the exact binary: re-grant it after a version bump.
#
# Consumed from modules/interface/default.nix as:
#     ./aerospace.nix
{ username, pkgs, ... }:
let
  workspaces = map toString [ 1 2 3 4 5 6 7 8 9 ];
  perWorkspace = f: builtins.listToAttrs (map f workspaces);

  # AeroSpace has no mode-change callback, so the bindings that switch mode
  # tell SketchyBar's service-mode indicator
  # (sketchybar/config/items/aerospace_mode.lua) themselves.
  toMode = m: [
    "mode ${m}"
    "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_mode_change MODE=${m}"
  ];
  # Run a service-mode command, then drop back to main mode.
  service = cmd: [ cmd ] ++ toMode "main";
in
{
  services.aerospace = {
    enable = true;
    # Unstable: fast-moving 0.x beta that tracks new macOS releases.
    package = pkgs.unstable.aerospace;

    settings = {
      # Keep tiled windows clear of the custom bars, neither of which
      # reserves screen space. Same values as Rectangle's screen-edge gaps
      # (modules/interface/rectangle.nix) — keep them in step.
      gaps.outer = {
        top = 8;
        bottom = 76;
        left = 0;
        right = 0;
      };

      # Pin apps to workspaces as their windows open. Match on the bundle ID
      # (`aerospace list-windows --all --format '%{app-bundle-id}'`).
      on-window-detected = [
        { "if".app-id = "com.gitbutler.app"; run = "move-node-to-workspace 0"; }
        { "if".app-id = "com.spotify.client"; run = "move-node-to-workspace 9"; }
        # Keep last (the first matching rule wins). On startup — `ns` or
        # login — AeroSpace puts every already-open window on the first
        # workspace, 0; send everything not pinned above to 1 instead.
        { "if".during-aerospace-startup = true; run = "move-node-to-workspace 1"; }
      ];

      # Workspaces that exist even when empty — what SketchyBar's spaces
      # widget builds its pills from. AeroSpace infers 1–9 from the bindings
      # below, but not 0 (bound to § rather than a digit).
      persistent-workspaces = [ "0" ] ++ workspaces;
      # Start on 1 rather than the first workspace in the list (0).
      after-startup-command = [ "workspace 1" ];

      mode.main.binding = {
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        alt-shift-semicolon = toMode "service";

        # Swap SketchyBar between app menus and workspaces, as its switch
        # icon does (sketchybar/config/items/menus.lua).
        alt-backtick = "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger swap_menus_and_spaces";
      }
      // perWorkspace (w: { name = "alt-${w}"; value = "workspace ${w}"; })
      // perWorkspace (w: { name = "alt-shift-${w}"; value = "move-node-to-workspace ${w}"; })
      // {
        # Workspace 0, on the § key left of 1 (British/ISO keyboards).
        alt-sectionSign = "workspace 0";
        alt-shift-sectionSign = "move-node-to-workspace 0";
      };

      mode.service.binding = {
        esc = service "reload-config";
        r = service "flatten-workspace-tree";
        f = service "layout floating tiling";

        alt-shift-h = service "join-with left";
        alt-shift-j = service "join-with down";
        alt-shift-k = service "join-with up";
        alt-shift-l = service "join-with right";
      };
    };
  };

  # Ghostty: ⌘T opens a new window rather than a tab, so each shell is its
  # own window for AeroSpace to tile. Appends to the config file declared in
  # modules/core/dev.nix.
  home-manager.users.${username}.xdg.configFile."ghostty/config".text = ''
    keybind = super+t=new_window
  '';
}
