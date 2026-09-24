# The agenix machinery, the env-var secrets, and git commit signing through
# 1Password. Other secrets are declared
# by the module that uses them (MailMate, SketchyBar). secrets.nix is read
# by the `agenix` CLI, not the module system, so it isn't imported here.
#
# Wiring (in flake.nix):
#     ./modules/secrets
{ agenix, username, ... }:
{
  imports = [
    ./agenix.nix
    ./envvars.nix
    ./git-signing.nix
  ];
}
