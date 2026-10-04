{ pkgs, ... }: {
  # Typst typesetting CLI, plus Tinymist — the VS Code extension for
  # Typst (language server, preview, export). The nixpkgs extension ships
  # with its own tinymist server binary, so nothing else to install.
  home.packages = [ pkgs.typst ];

  programs.vscode.profiles.default.extensions = [
    pkgs.vscode-extensions.myriad-dreamin.tinymist
  ];
}
