# AeroSpace — i3-style tiling window manager with its own virtual
# workspaces (no native Spaces, no SIP changes). nix-darwin's module writes
# the settings below to a store-path aerospace.toml and runs the app from a
# launchd user agent, so AeroSpace's own start-at-login stays off.
#
# A custom config replaces AeroSpace's built-in one wholesale, so the key
# bindings below are its defaults re-declared (minus the alt-<letter>
# workspaces, which clobber ⌥-typed characters). Anything not listed is
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

        alt-shift-semicolon = "mode service";
      }
      // perWorkspace (w: { name = "alt-${w}"; value = "workspace ${w}"; })
      // perWorkspace (w: { name = "alt-shift-${w}"; value = "move-node-to-workspace ${w}"; });

      mode.service.binding = {
        esc = [ "reload-config" "mode main" ];
        r = [ "flatten-workspace-tree" "mode main" ];
        f = [ "layout floating tiling" "mode main" ];
        backspace = [ "close-all-windows-but-current" "mode main" ];

        alt-shift-h = [ "join-with left" "mode main" ];
        alt-shift-j = [ "join-with down" "mode main" ];
        alt-shift-k = [ "join-with up" "mode main" ];
        alt-shift-l = [ "join-with right" "mode main" ];
      };
    };
  };
}
