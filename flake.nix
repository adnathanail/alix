{
  description = "darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # claude-code tracks raw `master` rather than the `nixpkgs-unstable`
    # channel branch. `nixpkgs-unstable` only advances once Hydra's
    # build/test gate promotes a `master` commit, which can lag same-day
    # package bumps (e.g. a new claude-code release) by hours to a day.
    # Since the overlay only cherry-picks the single claude-code derivation
    # (a fetchurl'd binary, not a build with a wide dependency surface), the
    # usual risk of tracking unvetted `master` is low here.
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Homebrew's tap metadata, pinned in flake.lock so cask/formula versions
    # only move when `nix flake update homebrew-cask` (or -core) is run.
    # `flake = false` — these are plain git checkouts, not flakes.
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nixpkgs-unstable, nixpkgs-master, home-manager, nix-homebrew, homebrew-core, homebrew-cask, agenix }:
  let
    username = "adnathanail";        # `whoami`
    hostname = "Alexs-MacBook-Pro";  # `scutil --get LocalHostName`

    # Everything stays on stable by default. This exposes the fresher package
    # sets as `pkgs.unstable` and `pkgs.master`, so each module picks its own
    # newer package where it's used (core/dev.nix, core/vscode.nix,
    # interface/sketchybar/) instead of swapping it here.
    unstableOverlay = final: prev:
      let
        unstable = import nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;   # vscode is unfree
        };
        # claude-code tracks raw master — see the nixpkgs-master input comment.
        master = import nixpkgs-master {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      in {
        inherit unstable master;
      };
  in {
    darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
      modules = [

        # ── secrets: agenix machinery + env-var secrets ────────
        (import ./modules/secrets { inherit agenix username; })

        # ── core: Claude Code, Ghostty, GitButler, VS Code ─────
        (import ./modules/core { inherit username; })

        # ── apps ────────────────────────────────────────────────
        (import ./modules/apps { inherit username; })

        # ── interface: SketchyBar, macOS settings, Rectangle, … ─
        (import ./modules/interface { inherit username; })

        # ── Graveyard: where things go to die ─
        ./modules/graveyard.nix

        # ── system ──────────────────────────────────────────────
        ({ pkgs, ... }: {
          nixpkgs.hostPlatform = "aarch64-darwin"; # "x86_64-darwin" on Intel
          nixpkgs.overlays = [ unstableOverlay ];
          nixpkgs.config.allowUnfree = true;

          system.stateVersion = 6;
          system.primaryUser = username;

          # Lix installer owns Nix + /etc/nix/nix.conf.
          nix.enable = false;

          users.users.${username}.home = "/Users/${username}";

          environment.systemPackages = [ ];

          # Homebrew — used only for GUI casks that don't tolerate the
          # Nix store layout (e.g. 1Password's anti-tamper check refuses
          # to run anywhere except /Applications/<app>.app). nix-homebrew
          # installs Homebrew itself; the `homebrew.*` options below
          # declare what gets installed via it.
          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = false;
              upgrade = true;
              cleanup = "zap";  # Uninstalls everything not declared here
            };
            # `brew bundle` skips casks marked `auto_updates true` (most GUI
            # apps) unless told otherwise, so without this `ns` would never
            # upgrade them — and self-updating is deliberately off for some
            # of them (Ghostty's Sparkle, Microsoft AutoUpdate). Upgrades go
            # only as far as the tap pins in flake.lock (see nix-homebrew.taps
            # below), so `ns` is reproducible: bump with
            # `nix flake update homebrew-cask`.
            greedyCasks = true;
            # Casks and brews: modules/apps/other.nix (plus any feature module
            # that brings its own, e.g. mailmate.nix, microsoft.nix).
          };
        })

        # ── Homebrew (nix-homebrew) ─────────────────────────────
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = username;
            # Apple Silicon installs to /opt/homebrew. Set
            # `enableRosetta = true` only if an x86_64-only cask
            # needs to be installed alongside the aarch64 brew.
            enableRosetta = false;

            # Taps come from the flake inputs above, so the whole cask/formula
            # catalogue is pinned by flake.lock — `ns` can only ever install
            # what the pinned metadata describes. Because homebrew-core is
            # tapped, nix-homebrew's brew wrapper also sets
            # HOMEBREW_NO_INSTALL_FROM_API=1, so brew reads these checkouts
            # instead of the live formulae.brew.sh API.
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };

            # Fully declarative: `brew tap` / `brew update` are refused, and
            # the wrapper exports HOMEBREW_NO_AUTO_UPDATE=1.
            mutableTaps = false;
          };
        }

        # Keep `homebrew.taps` (what `brew bundle` expects) in step with the
        # Nix-managed taps above, so activation never tries to tap anything.
        ({ config, ... }: {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        })

        # ── Home Manager ──────────────────────────
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;     # use the overlaid pkgs above
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";

          home-manager.users.${username} = import ./home.nix;
        }
      ];
    };
  };
}
