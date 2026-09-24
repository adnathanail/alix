{ pkgs, ... }: {
  # From stable nixpkgs, deliberately — see CLAUDE.md.
  home.packages = [ pkgs.jetbrains.pycharm ];

  # PyCharm keymap. Symlinked into the versioned config dir; bump the path
  # below after a JetBrains minor-version upgrade. Select it in
  # Settings → Keymap on first use; it appears as "Default for macOS copy".
  home.file."Library/Application Support/JetBrains/PyCharm2026.2/keymaps/custom-keymap.xml".source =
    ./custom-keymap.xml;
}
