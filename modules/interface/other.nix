# Interface tools too small for a module of their own.
#
# Consumed from flake.nix as:
#     ./modules/interface/other.nix
{
  # Raycast — launcher. Login Items helper + system-wide hotkey; the
  # default ⌥Space collides with Spotlight (onboarding offers to disable it).
  homebrew.casks = [ "raycast" ];
}
