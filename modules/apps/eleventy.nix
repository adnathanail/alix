{ pkgs, ... }: {
  # Nunjucks template language support for Eleventy. Not in the prebuilt
  # nixpkgs extension set, so pulled from the marketplace — bump version +
  # hash together.
  programs.vscode.profiles.default.extensions = [
    (pkgs.vscode-utils.extensionFromVscodeMarketplace {
      publisher = "ronnidc";
      name = "nunjucks";
      version = "1.0.1";
      sha256 = "sha256-I/Je6ACGyY0YDKwwV2Tif2muLPU1urhTqPfb7yvbcXc=";
    })
  ];
}
