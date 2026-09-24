# Mac App Store apps that aren't dev tooling or Safari extensions.
#
# Find IDs with `mas search <name>`.
#
# Consumed from flake.nix as:
#     ./modules/apps/macapps.nix
{
  homebrew.masApps = {
    iMovie = 408981434;
    # The 2024 rewrite, not "Reeder Classic" (1529448980).
    Reeder = 6475002485;
    # Keep-awake menu bar app. Free, MAS-only (no cask exists).
    Amphetamine = 937984704;
  };
}
