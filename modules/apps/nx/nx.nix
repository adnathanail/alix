{ pkgs, ... }:
let
  version = "23.2.1";
  # Wrapper "project" alongside this file pins nx as a dependency;
  # buildNpmPackage reads its package-lock.json to fetch every transitive
  # dep as a fixed-output derivation. Bump: edit ./package.json, rerun
  # `npm install --package-lock-only --ignore-scripts` in that dir, then
  # set npmDepsHash to pkgs.lib.fakeHash and let the build print the real
  # one.
  nx = pkgs.buildNpmPackage {
    pname = "nx";
    inherit version;
    # Just the npm files, so editing this .nix doesn't change the source.
    src = pkgs.lib.fileset.toSource {
      root = ./.;
      fileset = pkgs.lib.fileset.unions [ ./package.json ./package-lock.json ];
    };
    npmDepsHash = "sha256-2P5Kp+QC8+OTtYXj8CvR72A/QL3/JPCcmbvjDC78wvI=";
    dontNpmBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/nx $out/bin
      cp -r node_modules package.json package-lock.json $out/lib/nx/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/nx \
        --add-flags "$out/lib/nx/node_modules/nx/dist/bin/nx.js"
      runHook postInstall
    '';
  };
in {
  home.packages = [ nx ];
}
