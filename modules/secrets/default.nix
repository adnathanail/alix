# The agenix machinery plus the env-var secrets. Other secrets are declared
# by the module that uses them (MailMate, SketchyBar). secrets.nix is read
# by the `agenix` CLI, not the module system, so it isn't imported here.
#
# Wiring (in flake.nix):
#     (import ./modules/secrets { inherit agenix username; })
{ agenix, username }:
{
  imports = [
    (import ./agenix.nix { inherit agenix username; })
    (import ./envvars.nix { inherit username; })
  ];
}
