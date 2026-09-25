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
{ username, lib, pkgs, ... }:
let
  # Unstable: fast-moving 0.x beta that tracks new macOS releases.
  aerospace = pkgs.unstable.aerospace;

  profiles = import ./profiles.nix;

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

  # Window rules sending a profile's windows (see ./profiles.nix) to its
  # workspace: its apps, Safari windows in its Safari profile (Safari starts
  # each window's title with the profile name), and VS Code windows titled
  # "<name> - …" — a new project window takes you along with it.
  profileRules = p:
    let
      ws = toString p.workspace;
      titled = appId: prefix: run: {
        "if" = {
          app-id = appId;
          window-title-regex-substring = "^${prefix}";
        };
        inherit run;
      };
    in
    map (app: { "if".app-id = app; run = "move-node-to-workspace ${ws}"; }) (p.apps or [ ])
    ++ [
      (titled "com.apple.Safari" "${p.name} — " "move-node-to-workspace ${ws}")
      (titled "com.microsoft.VSCode" "${p.name} - "
        "move-node-to-workspace --focus-follows-window ${ws}")
    ];

  # Sends every window with a rule home: re-runs the window rules below
  # (on-window-detected) on every window. The VS Code profile rules take
  # focus along, so it returns you to the workspace you were on afterwards.
  # Bound to service mode's S; also on PATH as `aerospace-sort`.
  aerospaceSort = pkgs.writeShellScriptBin "aerospace-sort" ''
    aerospace=${aerospace}/bin/aerospace
    ws=$($aerospace list-workspaces --focused)
    $aerospace run-callback --for-every-window on-window-detected
    $aerospace workspace "$ws"
  '';

  # An app can show a window before it has its final title (VS Code often
  # does, before loading the project), so the profile rules can miss it.
  # The stray rules below run this for such windows: for 10s it re-reads the
  # window's title and moves it once a profile's prefix appears — the app's
  # "<name><separator>…", as in profileRules. Only for a new window: VS
  # Code's title changes with every file switched to, so watching for good
  # would undo manual moves. AEROSPACE_WINDOW_ID is the detected window.
  #   $1: the separator after the profile name
  #   $2: extra move-node-to-workspace flags (--focus-follows-window)
  titleWatch = pkgs.writeShellScript "aerospace-title-watch" ''
    aerospace=${aerospace}/bin/aerospace
    sep=$1
    flags=$2
    id=''${AEROSPACE_WINDOW_ID:-$($aerospace list-windows --focused --format '%{window-id}')}
    [ -n "$id" ] || exit 0
    for _ in $(seq 20); do
      sleep 0.5
      title=$($aerospace list-windows --all --format '%{window-id}|%{window-title}' \
        | sed -n "s/^$id|//p")
      [ -n "$title" ] || exit 0 # window closed
      case "$title" in
    ${lib.concatMapStrings (p: ''
        "${p.name}$sep"*) exec $aerospace move-node-to-workspace $flags --window-id "$id" ${toString p.workspace} ;;
    '') profiles}  esac
    done
  '';

  # Rules for an app's windows that matched no profile rule. Opened on a
  # profile's workspace, they go to 1 — they don't belong there; anywhere
  # else, they stay put. Either way titleWatch moves them on if a profile's
  # title turns up late. Must come after profileRules (first match wins).
  strays = appId: sep: flags:
    let watch = "exec-and-forget ${titleWatch} '${sep}' '${flags}'"; in
    map (p: {
      "if" = {
        app-id = appId;
        workspace = toString p.workspace;
      };
      run = [ "move-node-to-workspace 1" watch ];
    }) profiles
    ++ [{
      "if".app-id = appId;
      run = watch;
      # Still let the startup rule send it to 1.
      check-further-callbacks = true;
    }];
in
{
  environment.systemPackages = [ aerospaceSort ];

  # Group windows by app in Mission Control. AeroSpace parks windows from
  # other workspaces off-screen, which otherwise shrinks them to slivers in
  # Mission Control; AeroSpace's docs recommend this.
  system.defaults.dock.expose-group-apps = true;

  services.aerospace = {
    enable = true;
    package = aerospace;

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
        { "if".app-id = "com.freron.MailMate"; run = "move-node-to-workspace 8"; }
        { "if".app-id = "com.spotify.client"; run = "move-node-to-workspace 9"; }
      ]
      # The profiles' workspaces (./profiles.nix), then the Safari and VS
      # Code windows that matched none of them.
      ++ lib.concatMap profileRules profiles
      ++ strays "com.apple.Safari" " — " ""
      ++ strays "com.microsoft.VSCode" " - " "--focus-follows-window"
      ++ [
        # Except 1Password, whose unlock/approval prompts pop up over
        # GitButler when it signs a commit: leave those on 0 rather than
        # dragging you off to 1. The move is a no-op; matching is what stops
        # the rule below from firing.
        {
          "if" = {
            app-id = "com.1password.1password";
            workspace = "0";
            during-aerospace-startup = false;
          };
          run = "move-node-to-workspace 0";
        }

        # 0 is GitButler's alone (pinned first, above): anything else opened
        # there goes to 1, taking you with it. Not at startup, when every
        # window starts on 0 — the rule below handles that.
        {
          "if" = {
            workspace = "0";
            during-aerospace-startup = false;
          };
          run = "move-node-to-workspace --focus-follows-window 1";
        }

        # Keep last (the first matching rule wins). On startup — `ns` or
        # login — AeroSpace puts every already-open window on the first
        # workspace, 0; send everything not pinned above to 1 instead.
        { "if".during-aerospace-startup = true; run = "move-node-to-workspace 1"; }
      ];

      # New workspaces stack their windows as an accordion (the focused one
      # fills the space) rather than tiling them side by side. ⌥/ still
      # switches a workspace to tiles.
      default-root-container-layout = "accordion";

      # Prevent ⌘H hiding apps
      automatically-unhide-macos-hidden-apps = true;

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
        # icon does (sketchybar/config/items/menus.lua) — or, while the
        # native menu bar is showing, go back to SketchyBar
        # (sketchybar/config/items/menubar.lua).
        alt-backtick = "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger menus_key";
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
        s = service "exec-and-forget ${aerospaceSort}/bin/aerospace-sort";

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
