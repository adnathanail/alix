# clonager: keeps track of the git clones on this laptop. Installed from its
# own flake (the `clonager` input).
#
# Its config lists every repo URL, so it's an agenix secret
# (modules/secrets/agefiles/clonager-config.age) rather than a plain file in
# the repo. agenix decrypts it to /run/agenix/clonager-config, which the
# installed config links to. `clonager discover` edits the .age file through
# the decrypt/encrypt commands below; review, commit, then `ns` to apply.
# To edit by hand:
#   cd modules/secrets && agenix -e agefiles/clonager-config.age -i ~/.config/age/keys.txt
#
# A darwin module rather than an HM one because HM modules don't get the
# flake inputs through specialArgs.
{ username, clonager, agenix, pkgs, ... }:
let
  agenixBin = "${agenix.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/agenix";
  # agenix reads secrets.nix from the working directory.
  agenixCmd = flag:
    "cd ~/.config/nix-darwin/modules/secrets && ${agenixBin} ${flag} agefiles/clonager-config.age -i ~/.config/age/keys.txt";
in
{
  age.secrets.clonager-config = {
    file = ../../secrets/agefiles/clonager-config.age;
    owner = username;
    mode = "0400";
  };

  home-manager.users.${username} = {
    imports = [ clonager.homeModules.default ];

    programs.clonager = {
      enable = true;
      # A string, so it's linked to rather than copied into the store.
      configFile = "/run/agenix/clonager-config";
      configSource = {
        decrypt = agenixCmd "-d";
        encrypt = agenixCmd "-e";
      };
    };
  };
}
