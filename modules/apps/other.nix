# Apps too small for a module of their own.
#
# Homebrew is only for apps that need to live in /Applications or keep an
# intact vendor signature — everything else stays on Nix. Anything not
# declared in a homebrew.* list (here or in another module) is uninstalled
# on `ns`, since flake.nix sets cleanup = "zap".
#
# Consumed from modules/apps/default.nix as:
#     (import ./other.nix { inherit username; })
{ username }:
{ pkgs, ... }: {
  home-manager.users.${username}.home.packages = [
    # Rust reimplementation of pre-commit; from unstable because stable
    # lags this fast-moving 0.x tool.
    pkgs.unstable.prek
    pkgs.pnpm
    pkgs.gh
    pkgs.doctl
    pkgs.postgresql     # psql client
    # MySQL CLI: MariaDB's client-only output, since stable has no
    # client-only MySQL build (see CLAUDE.md → mysql CLI).
    pkgs.mariadb.client
  ];

  homebrew.casks = [
    "orbstack"
    "mimestream"
    "slack"
    "todoist-app"
    "fantastical"
    "spotify"
    "whatsapp"
    "google-drive"
    "steam"
    "capcut"
    "zoom"
    "audacity"
    "vlc"
    "gimp"
    "utm"
    "anki"
    "private-internet-access"
    "telegram"
    "signal"
    "brave-browser"
    "raindropio"
    "deepl"
    "dockflow"
  ];

  homebrew.brews = [
    # The Mac App Store CLI; needed for `homebrew.masApps`. Explicit so
    # `cleanup = "zap"` doesn't uninstall it.
    "mas"
    # PDF tools (pdftotext, pdftoppm, pdfinfo, …).
    "poppler"
  ];

  # Safari extensions, from the Mac App Store (find IDs with `mas search`).
  # These are container apps shipping a Safari App Extension; after install,
  # enable them in Safari → Settings → Extensions (that toggle is per-user
  # state, not Nix-managed).
  homebrew.masApps."Save to Raindrop.io" = 1549370672;
}
