# clonager: keeps track of the git clones on this laptop. Installed from its
# own flake (the `clonager` input), whose Home Manager module also installs
# ./clonager.yaml as ~/.config/clonager/config.yaml.
#
# A darwin module rather than an HM one because HM modules don't get the
# flake inputs through specialArgs.
{ username, clonager, ... }:
{
  home-manager.users.${username} = { config, ... }: {
    imports = [ clonager.homeModules.default ];

    programs.clonager = {
      enable = true;
      configFile = ./clonager.yaml;
      # `clonager discover` edits the checkout's copy; rebuild to apply.
      configSource = "${config.home.homeDirectory}/.config/nix-darwin/modules/apps/clonager/clonager.yaml";
    };
  };
}
