# Mac App Store apps that aren't dev tooling or Safari extensions.
# Currently: the Microsoft Office trio, iMovie, Reeder + Amphetamine.
#
# Find IDs with `mas search <name>`.
#
# Consumed from flake.nix as:
#     ./extra/macapps.nix
{
  homebrew.masApps = {
    "Microsoft Word" = 462054704;
    "Microsoft Excel" = 462058435;
    "Microsoft PowerPoint" = 462062816;
    iMovie = 408981434;
    # The 2024 rewrite, not "Reeder Classic" (1529448980).
    Reeder = 6475002485;
    # Keep-awake menu bar app. Free, MAS-only (no cask exists).
    Amphetamine = 937984704;
  };
}
