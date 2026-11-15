# Linux builder: a small aarch64-linux NixOS VM (nixpkgs' `darwin.linux-builder`)
# that the Nix daemon hands Linux builds to, e.g. for deploying NixOS to a
# Raspberry Pi.
#
# This recreates nix-darwin's `nix.linux-builder` module, which can't be used
# here because it needs `nix.enable` (see "nix.enable = false" in CLAUDE.md).
# The differences:
#   - The builder is registered through /etc/nix/machines instead of
#     `nix.buildMachines`. Lix's default `builders` setting is
#     `@/etc/nix/machines`, so nothing in the Lix-owned nix.conf changes.
#   - `builders-use-substitutes` is left off, so the builder's inputs are
#     downloaded by the Mac and copied into the VM rather than fetched by the
#     VM itself. Turn it on in /etc/nix/nix.custom.conf if that gets slow.
#
# The launchd daemon boots the VM at load and keeps it running. On first start,
# create-builder generates an SSH key pair under /var/lib/linux-builder/keys
# and installs it as /etc/nix/builder_ed25519.
#
# Check it works:  nix build --impure --expr '(import <nixpkgs> { system = "aarch64-linux"; }).hello' --rebuild
# Log into the VM:  sudo ssh linux-builder
#
# The VM's size (cores, memory, disk) uses nixpkgs' defaults. Resizing means
# overriding the package with extra NixOS modules, which needs a working
# builder to build the new VM image, so get the default one running first.
{ config, lib, pkgs, ... }:
let
  package = pkgs.darwin.linux-builder;
  workingDirectory = "/var/lib/linux-builder";
  systems = [ package.nixosConfig.nixpkgs.hostPlatform.system ];
  maxJobs = package.nixosConfig.virtualisation.cores;
  supportedFeatures = [ "kvm" "benchmark" "big-parallel" ];
  # The VM's fixed SSH host key (base64 of "ssh-ed25519 … root@nixos"), the same
  # value nix-darwin's module uses.
  publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpCV2N4Yi9CbGFxdDFhdU90RStGOFFVV3JVb3RpQzVxQkorVXVFV2RWQ2Igcm9vdEBuaXhvcwo=";
in
{
  system.activationScripts.preActivation.text = ''
    mkdir -p ${workingDirectory}
  '';

  launchd.daemons.linux-builder = {
    environment = {
      inherit (config.environment.variables) NIX_SSL_CERT_FILE;
    };

    # create-builder shares files (notably certs) with the VM through TMPDIR.
    # macOS deletes files in /tmp that haven't been accessed for 3+ days, so a
    # Mac left asleep that long would lose them; use a directory under /run
    # instead and clean it up here.
    script = ''
      export TMPDIR=/run/org.nixos.linux-builder USE_TMPDIR=1
      rm -rf $TMPDIR
      mkdir -p $TMPDIR
      trap "rm -rf $TMPDIR" EXIT
      ${package}/bin/create-builder
    '';

    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      WorkingDirectory = workingDirectory;
    };
  };

  environment.etc."ssh/ssh_config.d/100-linux-builder.conf".text = ''
    Host linux-builder
      User builder
      Hostname localhost
      HostKeyAlias linux-builder
      Port 31022
      IdentityFile /etc/nix/builder_ed25519
  '';

  # Format: URI systems ssh-key max-jobs speed-factor supported-features
  # mandatory-features public-host-key ("-" means none).
  environment.etc."nix/machines".text = ''
    ssh-ng://builder@linux-builder ${lib.concatStringsSep "," systems} /etc/nix/builder_ed25519 ${toString maxJobs} 1 ${lib.concatStringsSep "," supportedFeatures} - ${publicHostKey}
  '';
}
