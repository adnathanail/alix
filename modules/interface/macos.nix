# macOS system settings: Dock, menu-bar clock, Control Center, and
# system-wide keyboard shortcuts.
#
# Wiring (in flake.nix):
#     (import ./modules/interface/macos.nix { inherit username; })
{ username }:
{ ... }: {
  # Hide "Recent applications" section in the Dock.
  system.defaults.dock.show-recents = false;

  # Hot corners: top-left → Show Desktop (4), bottom-left → Apps/Launchpad (11). 1 = disabled.
  system.defaults.dock.wvous-tl-corner = 4;
  system.defaults.dock.wvous-bl-corner = 11;

  # Dock contents: Finder is always pinned leftmost by macOS, so
  # persistent-apps only covers what comes after it.
  system.defaults.dock.persistent-apps = [
    { app = "/Applications/Ghostty.app"; }
    { app = "/System/Cryptexes/App/System/Applications/Safari.app"; }
    { spacer = { small = true; }; }
    { app = "/Users/${username}/Applications/Home Manager Apps/Visual Studio Code.app"; }
    { app = "/Applications/GitButler.app"; }
    { spacer = { small = true; }; }
    { app = "/Applications/MailMate.app"; }
    { spacer = { small = true; }; }
  ];

  # Menu-bar clock: 24h time with seconds, no date.
  system.defaults.menuExtraClock = {
    Show24Hour = true;
    ShowSeconds = true;
    ShowDate = 2;            # 0 = when space allows, 1 = always, 2 = never
    ShowDayOfWeek = false;
    ShowDayOfMonth = false;
  };

  # Control Center / menu-bar items.
  system.defaults.controlcenter = {
    BatteryShowPercentage = true;
    Bluetooth = true;
  };

  # Clear the ⌘⇧A hotkey on the "Search man Page Index in Terminal"
  # service — it otherwise hijacks ⌘⇧A system-wide and breaks PyCharm's
  # Find Action. The service itself stays available in the Services menu.
  system.defaults.CustomUserPreferences."pbs" = {
    NSServicesStatus = {
      "com.apple.Terminal - Search man Page Index in Terminal - searchManPages" = {
        key_equivalent = "";
      };
    };
  };
}
