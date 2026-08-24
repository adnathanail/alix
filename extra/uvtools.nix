{ pkgs, lib, ... }:
let
  # Python CLI tools that aren't in nixpkgs
  #
  # Prefer a real nixpkgs package when one exists at an acceptable version;
  #  this is the escape hatch for when it doesn't.
  #
  # Attribute name = what you type 
  # value = the pip name/version (PEP 508) to install it from
  uvTools = {
    qi = "quantuminspire==3.5.3";
  };

  # Each entry becomes a tiny shell script in the store that shells out to
  #  `uv tool run`. uv resolves the spec into an ephemeral environment cached
  #  under ~/.cache/uv on first invocation and reuses it after — so the *shim*
  #  is declarative and Nix-managed, but the tool's own environment is uv's,
  #  not the Nix store's.
  # Consequences:
  #   - the first run of each tool needs network access;
  #   - versions are reproducible only because every spec is pinned to an
  #     exact `==` version — keep those pins;
  #   - `uv cache clean` costs a re-download, nothing more.
  #
  # `--from <spec> <name>` rather than plain `uv tool run <name>` so the
  # package installed from and the executable run stay decoupled.
  mkUvTool = name: spec: pkgs.writeShellScriptBin name ''
    exec ${pkgs.uv}/bin/uv tool run --from ${lib.escapeShellArg spec} ${lib.escapeShellArg name} "$@"
  '';
in {
  home.packages = lib.mapAttrsToList mkUvTool uvTools;

  # Put `uv tool install` shims on PATH
  #  (for uv tools installed without this shim)
  home.sessionPath = [ "$HOME/.local/bin" ];
}
