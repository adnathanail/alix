# `safari-window <profile>`: focuses an open Safari window in that Safari
# profile — one on the focused AeroSpace workspace if there is one — or else
# opens a new one, on the homepage. Plain function, not a module — called
# with `{ pkgs }` by its users: SketchyBar's Safari button
# (sketchybar/config.nix) and Hammerspoon's hyper+digit hotkeys
# (hammerspoon/default.nix).
#
# Safari starts each window's title with "<profile> — ", which is how open
# windows are matched.
#
# Safari can only open a profile's window from File → New Window, so that
# is clicked via System Events, which needs Accessibility — the caller's
# (osascript runs as its child), so SketchyBar's or Hammerspoon's. The
# window opens on the profile's own start page; the homepage is then loaded
# into it, once it has appeared. It opens on the focused workspace;
# aerospace.nix's rules keep it there.
{ pkgs }:
let
  homepage = "https://newtab.adnathanail.dev";
  aerospace = "${pkgs.unstable.aerospace}/bin/aerospace";
in
pkgs.writeShellScriptBin "safari-window" ''
  profile=$1
  ws=$(${aerospace} list-workspaces --focused)
  id=$(${aerospace} list-windows --all \
      --format '%{window-id}|%{workspace}|%{app-bundle-id}|%{window-title}' \
    | /usr/bin/awk -F'|' -v ws="$ws" -v prefix="$profile — " '
        $3 == "com.apple.Safari" && index($4, prefix) == 1 {
          if ($2 == ws) { here = $1; exit }
          if (!found) found = $1
        }
        END { print (here ? here : found) }')
  if [ -n "$id" ]; then
    exec ${aerospace} focus --window-id "$id"
  fi

  exec /usr/bin/osascript - "$profile" <<'EOF'
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
