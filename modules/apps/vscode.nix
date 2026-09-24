{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    # HM fully owns ~/.vscode/extensions. VS Code's marketplace-install
    # path can no longer rewrite extensions.json and desync the manifest
    # from the on-disk symlinks. Trade-off: extensions can only be added
    # by editing this file (or coq.nix etc.) and rebuilding.
    mutableExtensionsDir = false;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        ms-vscode-remote.remote-containers
        anthropic.claude-code
        ms-python.python
        tomoki1207.pdf
        tamasfe.even-better-toml
        leanprover.lean4
      ] ++ [
        # TikZiT — graphical editor for TikZ diagrams (.tikz files). Not in
        # the prebuilt nixpkgs extension set, so it comes straight from the
        # marketplace; bump version + sha256 together.
        (pkgs.vscode-utils.extensionFromVscodeMarketplace {
          publisher = "alekskissinger";
          name = "vstikzit";
          version = "0.5.2";
          sha256 = "sha256-+Xnv6RT7xxGmQItzR0k7Xp0N3Bu6Em214LEHSZud20M=";
        })
        # GitButler for IDE — shows the GitButler branch/stack state inside
        # VS Code. Not in the prebuilt nixpkgs extension set, so it comes
        # straight from the marketplace; bump version + sha256 together.
        (pkgs.vscode-utils.extensionFromVscodeMarketplace {
          publisher = "BartInTheField";
          name = "gitbutler-for-ide";
          version = "2026.8.9";
          sha256 = "sha256-E9kb7pKuR5Ds9h863tWR1Ls184KEyXdecXbq6OglxUE=";
        })
        # Highlight — regex-driven decorations for arbitrary patterns (TODOs,
        # custom annotations) in any language. Not in the prebuilt nixpkgs
        # extension set, so it comes straight from the marketplace; bump
        # version + sha256 together.
        (pkgs.vscode-utils.extensionFromVscodeMarketplace {
          publisher = "fabiospampinato";
          name = "vscode-highlight";
          version = "2.1.0";
          sha256 = "sha256-pZZHV9vcF5bx3DE4AyoNoPdzzhPE+DlhK1kQg5+pwGI=";
        })
      ];
      userSettings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
        "git.enableSmartCommit" = true;
        "git.autofetch" = true;
        "git.confirmSync" = false;
        # Extensions come from Nix; the store is read-only so VS Code's
        # in-app updater can't write to them.
        "extensions.autoUpdate" = "off";
        "extensions.autoCheckUpdates" = false;
        "lean4.alwaysAskBeforeInstallingLeanVersions" = false;
        "github.copilot.enable" = {
          "*" = false;
          "plaintext" = false;
          "markdown" = false;
          "scminput" = false;
        };
        "workbench.browser.openLocalhostLinks" = false;  # Don't open links in VS Code browser
        "claudeCode.useTerminal" = true;  # Open Claude code in terminal
      };
      keybindings = [
        { key = "cmd+s"; command = "workbench.action.files.saveAll"; }
        { key = "cmd+1"; command = "workbench.action.openEditorAtIndex1"; }
        { key = "cmd+2"; command = "workbench.action.openEditorAtIndex2"; }
        { key = "cmd+3"; command = "workbench.action.openEditorAtIndex3"; }
        { key = "cmd+4"; command = "workbench.action.openEditorAtIndex4"; }
        { key = "cmd+5"; command = "workbench.action.openEditorAtIndex5"; }
        { key = "cmd+6"; command = "workbench.action.openEditorAtIndex6"; }
        { key = "cmd+7"; command = "workbench.action.openEditorAtIndex7"; }
        { key = "cmd+8"; command = "workbench.action.openEditorAtIndex8"; }
        { key = "cmd+9"; command = "workbench.action.openEditorAtIndex9"; }
        { key = "cmd+0"; command = "workbench.action.lastEditorInGroup"; }
      ];
    };
  };
}
