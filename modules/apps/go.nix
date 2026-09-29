{ pkgs, ... }: {
  # Go toolchain (go, gofmt) via Home Manager's programs.go.
  programs.go.enable = true;

  # Go language support for VS Code.
  programs.vscode.profiles.default.extensions = [
    pkgs.vscode-extensions.golang.go
  ];
}
