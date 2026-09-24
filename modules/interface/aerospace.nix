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
{ pkgs, ... }:
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
        { "if".app-id = "com.spotify.client"; run = "move-node-to-workspace 9"; }
      ];

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
      }
      // perWorkspace (w: { name = "alt-${w}"; value = "workspace ${w}"; })
      // perWorkspace (w: { name = "alt-shift-${w}"; value = "move-node-to-workspace ${w}"; });

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
}
