# aerospace-swipe — four-finger horizontal swipes switch AeroSpace
# workspaces, standing in for macOS's swipe between Spaces (AeroSpace
# doesn't use Spaces, so the native gesture has nothing to move between).
# https://github.com/acsandmann/aerospace-swipe
#
# It reads the trackpad through a listen-only event tap, so it can't
# swallow the native gesture: macOS's own four-finger (and three-finger)
# Spaces swipe is switched off below, or both would fire.
#
# Not in nixpkgs, so it's built here from a pinned commit (the upstream
# makefile hard-codes -march=native and an install step, so the compile is
# done by hand). Only its haptics use the private MultitouchSupport
# framework; the trackpad itself is read through public AppKit APIs.
#
# Needs Accessibility (for the event tap). The binary is ad-hoc signed, so
# the grant is pinned to its store path: re-grant after any rebuild of it —
# a pin bump, or a nixpkgs update that changes the toolchain. It prompts for
# the grant itself, and waits until it's given.
#
# Consumed from modules/interface/default.nix as:
#     ./aerospace-swipe.nix
{ config, username, lib, pkgs, ... }:
let
  aerospace = config.services.aerospace;

  aerospaceSwipe = pkgs.stdenv.mkDerivation {
    pname = "aerospace-swipe";
    version = "0-unstable-2026-09-16";
    src = pkgs.fetchFromGitHub {
      owner = "acsandmann";
      repo = "aerospace-swipe";
      rev = "7e06fe41e0deff786a643bf4d56963104c459c12";
      hash = "sha256-97vCTspK+0JXfYUw7PiRK7ST9YhIV/Ra0VO/W7FeTUw=";
    };
    buildPhase = ''
      runHook preBuild
      $CC -std=c99 -O2 -fobjc-arc \
        -Wno-pointer-integer-compare -Wno-incompatible-pointer-types-discards-qualifiers \
        -o swipe src/aerospace.c src/yyjson.c src/haptic.c src/event_tap.m src/main.m \
        -framework CoreFoundation -framework IOKit -framework ApplicationServices -framework Cocoa \
        -F/System/Library/PrivateFrameworks -framework MultitouchSupport
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 swipe $out/bin/aerospace-swipe
      runHook postInstall
    '';
    meta.license = lib.licenses.mit;
  };
in
lib.mkIf aerospace.enable {
  # Turn off macOS's swipe between Spaces / full-screen apps, for both three
  # and four fingers, so only aerospace-swipe answers a horizontal swipe.
  # (Mission Control's vertical swipes are left alone.) May need a logout to
  # take effect.
  system.defaults.trackpad = {
    TrackpadFourFingerHorizSwipeGesture = 0;
    TrackpadThreeFingerHorizSwipeGesture = 0;
  };

  launchd.user.agents.aerospace-swipe = {
    serviceConfig = {
      ProgramArguments = [ "${aerospaceSwipe}/bin/aerospace-swipe" ];
      EnvironmentVariables = {
        # Names its lock file (/tmp/aerospace-swipe-$USER.lock).
        USER = username;
        # It talks to AeroSpace's socket, falling back to the `aerospace` CLI.
        PATH = "${lib.makeBinPath [ aerospace.package ]}:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${username}/Library/Logs/aerospace-swipe.log";
      StandardErrorPath = "/Users/${username}/Library/Logs/aerospace-swipe.err.log";
    };
  };

  # Read once at startup; the agent's plist doesn't change when only this
  # does, so restart it by hand after editing:
  #     launchctl kickstart -k gui/$(id -u)/org.nixos.aerospace-swipe
  home-manager.users.${username}.xdg.configFile."aerospace-swipe/config.json".text =
    builtins.toJSON {
      fingers = 4;
      # Match macOS: fingers moving left go to the next workspace. Upstream's
      # "natural" is the reverse of what its docs say — true is macOS's way.
      natural_swipe = true;
      # macOS stops at the first and last Space rather than wrapping.
      wrap_around = false;
      # Only step through workspaces with windows on them, not all ten.
      skip_empty = true;
      haptic = false;
    };
}
