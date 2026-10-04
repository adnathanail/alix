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
# Needs Accessibility (for the event tap). The store binary is only ad-hoc
# signed, which would void the grant on every rebuild of it, so launchd runs
# a copy at a fixed path re-signed with a stable identity, the same way as
# SketchyBar — see ./signing.nix. Grant Accessibility to that copy
# (~/.local/libexec/aerospace-swipe/aerospace-swipe), once. It prompts for
# the grant itself, and waits until it's given.
#
# Consumed from modules/interface/default.nix as:
#     ./aerospace-swipe.nix
{ config, username, lib, pkgs, ... }:
let
  aerospace = config.services.aerospace;

  # The binary launchd runs: a stable-path, stably-signed copy of
  # aerospaceSwipe (./signing.nix). This path is what the Accessibility grant
  # is given to, so don't move it.
  signedBin = "/Users/${username}/.local/libexec/aerospace-swipe/aerospace-swipe";
  signAerospaceSwipe = import ./signing.nix {
    inherit pkgs;
    name = "aerospace-swipe";
    identifier = "com.acsandmann.aerospace-swipe";
  };

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
  # Shared with SketchyBar, which declares it identically (the definitions
  # merge); declared here too so this works without SketchyBar.
  age.secrets.alix-local-signing-identity = {
    file = ../secrets/agefiles/alix-local-signing-identity.age;
    owner = username;
    mode = "0400";
  };

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
      ProgramArguments = [ signedBin ];
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

  # Re-sign after each rebuild, then restart it so it runs the new copy
  # (its plist names the fixed path, so it doesn't change and nix-darwin
  # won't restart it). Runs as the user so the copy is user-owned; mkAfter,
  # as for SketchyBar's. A signing failure is reported but doesn't fail
  # activation; the previous signed copy keeps running.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    launchctl asuser "$(id -u -- ${username})" \
      sudo --user=${username} -- \
      ${signAerospaceSwipe} ${aerospaceSwipe}/bin/aerospace-swipe \
        /run/agenix/alix-local-signing-identity ${signedBin} \
      || echo "aerospace-swipe: signing failed; its Accessibility grant may not apply" >&2
    launchctl asuser "$(id -u -- ${username})" \
      sudo --user=${username} -- \
      launchctl kickstart -k "gui/$(id -u -- ${username})/org.nixos.aerospace-swipe" \
      2>/dev/null || true
  '';
}
