# `safari-new-window <profile>`: opens a new Safari window in that Safari
# profile, on the homepage. Plain function, not a module — called with
# `{ pkgs }` by its users: SketchyBar's Safari button
# (sketchybar/config.nix) and Hammerspoon's hyper+digit hotkeys
# (hammerspoon/default.nix).
#
# Safari can only open a profile's window from File → New Window, so that
# is clicked via System Events, which needs Accessibility — the caller's
# (osascript runs as its child), so SketchyBar's or Hammerspoon's. The
# window opens on the profile's own start page; the homepage is then loaded
# into it, once it has appeared.
{ pkgs }:
let
  homepage = "https://newtab.adnathanail.dev";
in
pkgs.writeShellScriptBin "safari-new-window" ''
  exec /usr/bin/osascript - "$1" <<'EOF'
  on run argv
    set profileName to item 1 of argv
    tell application "Safari"
      activate
      set existing to count windows
    end tell
    tell application "System Events" to tell process "Safari"
      repeat until exists menu bar item "File" of menu bar 1
        delay 0.1
      end repeat
      click menu item ("New " & profileName & " Window") of menu 1 of menu item ¬
        "New Window" of menu 1 of menu bar item "File" of menu bar 1
    end tell
    tell application "Safari"
      repeat 50 times
        if (count windows) > existing then
          set URL of current tab of front window to "${homepage}"
          exit repeat
        end if
        delay 0.1
      end repeat
    end tell
  end run
  EOF
''
