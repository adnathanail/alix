# iOS/Android app dev tooling
#
# Consumed from flake.nix as:
#     ./modules/apps/appdev.nix
{
  homebrew.masApps = {
    Xcode = 497799835;
  };

  homebrew.casks = [ "android-studio" ];
}
