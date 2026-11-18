# lmao: a terminal UI for reviewing unreviewed Lunch Money transactions.
# Installed from its own flake (the `lmao` input).
#
# It reads its access token from the lunchmoney-token secret
# (modules/secrets/envvars.nix) each time it starts, so it works even
# where ~/.config/nix-secrets.env isn't sourced. A LUNCHMONEY_TOKEN already
# in the environment takes precedence.
#
# A darwin module rather than an HM one because HM modules don't get the
# flake inputs through specialArgs.
{ username, lmao, ... }:
{
  home-manager.users.${username} = {
    imports = [ lmao.homeModules.default ];

    programs.lmao = {
      enable = true;
      tokenFile = "/run/agenix/lunchmoney-token";
    };
  };
}
