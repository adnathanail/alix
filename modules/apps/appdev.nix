# iOS/Android app dev tooling
#
# Consumed from modules/apps/default.nix as:
#     ./appdev.nix
{
  homebrew.masApps = {
    Xcode = 497799835;
  };

  homebrew.casks = [ "android-studio" ];
}
