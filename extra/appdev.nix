# App-Store-distributed developer tooling (currently just Xcode).
#
# Xcode isn't in nixpkgs and Apple doesn't allow it as a Homebrew cask —
# distribution is App Store only. `homebrew.masApps` runs `mas install <id>`
# at activation; `mas` itself is pinned in `homebrew.brews` so the
# `cleanup = "zap"` in flake.nix doesn't uninstall the CLI that `masApps`
# depends on. Both option sets merge with whatever `flake.nix` declares.
#
# Requires being signed into the App Store *before* the first `ns` — modern
# `mas` cannot sign in from the CLI. If activation reports `Not signed in`,
# open the App Store app, sign in, then re-run `ns`.
#
# After first install, run once:
#   sudo xcodebuild -license accept
#   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
#
# Consumed from flake.nix as:
#     ./extra/appdev.nix
{
  homebrew.brews = [ "mas" ];

  # Find IDs with `mas search <name>`.
  homebrew.masApps = {
    Xcode = 497799835;
  };
}
