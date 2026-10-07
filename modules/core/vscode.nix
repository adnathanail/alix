{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    # Editor from unstable (pkgs.unstable, from flake.nix's unstableOverlay);
    # the extensions below stay on stable, which is fine — a newer editor
    # runs older extensions.
    package = pkgs.unstable.vscode;
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
        github.vscode-github-actions
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
        # gitbutler-vscode — custom VS Code extension
        # Not on the marketplace, so the .vsix comes from the
        # GitHub release; bump version + sha256 together.
        (pkgs.vscode-utils.buildVscodeMarketplaceExtension rec {
          mktplcRef = {
            publisher = "adnathanail";
            name = "gitbutler-vscode";
            version = "0.0.3";
          };
          vsix = pkgs.fetchurl {
            name = "${mktplcRef.publisher}-${mktplcRef.name}.vsix";
            url = "https://github.com/adnathanail/gitbutler-vscode/releases/download/v${mktplcRef.version}/gitbutler-vscode-v${mktplcRef.version}.vsix";
            sha256 = "sha256-Vgg48rJ6trhWLPiNYd345XHGVfna6nFmi8kWImtbRkw=";
          };
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
        # Open Claude code in terminal
        "claudeCode.useTerminal" = true;
        # Extensions come from Nix; the store is read-only so VS Code's
        # in-app updater can't write to them.
        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = "off";
        # Git config
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;
        # Disable copilot
        "github.copilot.enable" = {
          "*" = false;
          "plaintext" = false;
          "markdown" = false;
          "scminput" = false;
        };
        # Lean
        "lean4.alwaysAskBeforeInstallingLeanVersions" = true;
        # Nix
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
        # Allow opening `but` (GitButler) links
        "terminal.integrated.allowedLinkSchemes" = [
          "file"
          "http"
          "https"
          "mailto"
          "vscode"
          "vscode-insiders"
          "but"
        ];
        # Don't open links in VS Code browser
        "workbench.browser.openLocalhostLinks" = false;
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
