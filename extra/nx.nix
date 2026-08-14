{ pkgs, ... }:
let
  version = "23.1.1";
  # Wrapper "project" at ../nx pins nx as a dependency; buildNpmPackage
  # reads its package-lock.json to fetch every transitive dep as a fixed-
  # output derivation. Bump: edit ../nx/package.json, rerun
  # `npm install --package-lock-only --ignore-scripts` in that dir, then
  # set npmDepsHash to pkgs.lib.fakeHash and let the build print the real
  # one.
  nx = pkgs.buildNpmPackage {
    pname = "nx";
    inherit version;
    src = ../nx;
    npmDepsHash = "sha256-izHMddWBGCY50135ViNuW7ZjgS6smbE2NbnFA50p9tI=";
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
