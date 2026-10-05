# Hammerspoon — Lua desktop automation. https://www.hammerspoon.org
#
# Does Fn+2 → € and Fn+3 → # (./init.lua), in place of the ⌥-typed
# characters AeroSpace's bindings take over, and reads Slack's and MailMate's
# unread counts for SketchyBar's notifications item (./notifications.lua).
# Hyper + a workspace's digit focuses or opens a Safari window in that
# workspace's profile (./safari.lua, generated from ../profiles.nix).
#
# Homebrew rather than Nix: it's a signed app, so its Accessibility grant
# (needed for the event tap) survives updates, unlike an ad-hoc-signed Nix
# build's.
#
# Consumed from modules/interface/default.nix as:
#     ./hammerspoon
{ config, pkgs, lib, username, ... }:
let
  # Personal on 1, then each profile on its workspace — see ./safari.lua.
  safariProfiles = [ { workspace = 1; name = "Personal"; } ] ++ import ../profiles.nix;
  safariLua = pkgs.replaceVars ./safari.lua {
    aerospace = config.services.aerospace.package;
    safariWindow = import ../safari-window.nix { inherit pkgs; };
    profiles = "{\n"
      + lib.concatMapStrings (p: "  [\"${toString p.workspace}\"] = \"${p.name}\",\n") safariProfiles
      + "}";
  };
in
{
  homebrew.casks = [ "hammerspoon" ];

  system.defaults.CustomUserPreferences."org.hammerspoon.Hammerspoon" = {
    # Read the config from ~/.config rather than ~/.hammerspoon.
    MJConfigFile = "~/.config/hammerspoon/init.lua";
    # Updates come through the cask refresh on rebuild (Sparkle's own key).
    SUEnableAutomaticChecks = false;
    # No Dock icon; the menu-bar icon stays, for the console and reload.
    MJShowDockIconKey = false;
  };

  home-manager.users.${username}.xdg.configFile = {
    "hammerspoon/init.lua".source = ./init.lua;
    "hammerspoon/notifications.lua".source = ./notifications.lua;
    "hammerspoon/safari.lua".source = safariLua;
  };
}
