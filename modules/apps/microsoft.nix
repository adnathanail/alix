# Microsoft Office: Outlook (Homebrew cask), Word / Excel / PowerPoint
# (Mac App Store), and their Nix-managed preferences.
#
# Consumed from flake.nix as:
#     ./modules/apps/microsoft.nix
{
  homebrew.casks = [ "microsoft-outlook" ];

  homebrew.masApps = {
    "Microsoft Word" = 462054704;
    "Microsoft Excel" = 462058435;
    "Microsoft PowerPoint" = 462062816;
  };

  # Microsoft AutoUpdate (MAU): keep Office updates manual so they flow
  # through `darwin-rebuild` (Homebrew cask refresh), not MAU's
  # auto-installer. Applies to Outlook and any other Office app
  # installed later. MAU is a non-sandboxed helper so its prefs land at
  # ~/Library/Preferences/com.microsoft.autoupdate2.plist as expected.
  system.defaults.CustomUserPreferences."com.microsoft.autoupdate2" = {
    HowToCheck = "Manual";
  };

  # Outlook: privacy-leaning defaults. Outlook is sandboxed, but
  # Microsoft documents `defaults write com.microsoft.Outlook …` as the
  # supported mechanism — CFPreferences redirects writes through to the
  # container plist, so nix-darwin's standard `defaults write` works.
  system.defaults.CustomUserPreferences."com.microsoft.Outlook" = {
    # Block remote image loading (stops tracking pixels). User clicks
    # "Download Pictures" per message when they actually want them.
    AutomaticallyDownloadExternalContent = false;
    # Disable Focused Inbox — single chronological inbox, no AI sort.
    FocusedInbox = false;
  };

  # Office-wide telemetry: lowest level available on consumer accounts.
  # `BasicTelemetry` sends only required service data;
  # `ZeroTelemetry` is enterprise/government-tenant-only.
  system.defaults.CustomUserPreferences."com.microsoft.office" = {
    DiagnosticDataTypePreference = "BasicTelemetry";
  };
}
