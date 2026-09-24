# Profiles: the contexts the laptop is used for, each with its own AeroSpace
# workspace. Plain data, not a module — imported where it's used:
#   - aerospace.nix: sends each profile's windows to its workspace — Safari
#     windows in the Safari profile of the same name (Safari prefixes the
#     title with "<name> — "), VS Code windows titled "<name> - …", and any
#     `apps`, by bundle ID
#     (`aerospace list-windows --all --format '%{app-bundle-id}'`)
#     To label a VS Code project, put this in its .vscode/settings.json —
#     VS Code's default title with the prefix in front:
#       "window.title": "Fermioniq - ${activeEditorShort}${separator}${rootName}${separator}${profileName}"
#   - sketchybar/config.nix: colours the workspace's pill in the bar — a
#     faint tint of `colour` when inactive, the full colour when active
[
  {
    name = "Fermioniq"; # work
    workspace = 4;
    colour = "#ee8076";
    apps = [ "com.tinyspeck.slackmacgap" ]; # Slack
  }
  {
    name = "ASAC";
    workspace = 5;
    colour = "#d25bf7";
  }
]
