# macOS system settings: Dock, menu-bar clock, Control Center,
# system-wide keyboard shortcuts, and Touch ID for sudo.
#
# Consumed from modules/interface/default.nix as:
#     (import ./macos.nix { inherit username; })
{ username }:
{ ... }: {
  # Touch ID for sudo. Writes /etc/pam.d/sudo_local, which survives macOS
  # updates; doesn't work inside tmux without pam_reattach.
  security.pam.services.sudo_local.touchIdAuth = true;

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
