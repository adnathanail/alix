{ pkgs, ... }: {
  # Nunjucks template language support for Eleventy. Not in the prebuilt
  # nixpkgs extension set, so pulled from the marketplace — bump version +
  # hash together.
  programs.vscode.profiles.default.extensions = [
    (pkgs.vscode-utils.extensionFromVscodeMarketplace {
      publisher = "ronnidc";
      name = "nunjucks";
      version = "1.0.0";
      sha256 = "sha256-nlmgoZNcHUq6xxK4v4AYgkll06VsMJg4iI6CchvtpxU=";
    })
  ];
}
