# Mac App Store apps that aren't dev tooling or Safari extensions.
# Currently: the Microsoft Office trio + iMovie.
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
  };
}
