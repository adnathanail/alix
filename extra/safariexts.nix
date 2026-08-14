# Safari extensions distributed via the Mac App Store.
#
# These are container apps that ship a Safari App Extension bundle; after
# install, enable them in Safari → Settings → Extensions. The extension
# toggle itself is per-user state and not Nix-managed.
#
# Find IDs with `mas search <name>`.
#
# Consumed from flake.nix as:
#     ./extra/safariexts.nix
{
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
    "Save to Raindrop.io" = 1549370672;
  };
}
