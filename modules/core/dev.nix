# Core dev tools: Claude Code, Ghostty, GitButler.
#
# Consumed from modules/core/default.nix as:
#     ./dev.nix
{ username, ... }: {
  # Ghostty needs Homebrew: pkgs.ghostty on Darwin is fragile (Swift/Xcode
  # toolchain). GitButler needs /Applications.
  homebrew.casks = [ "ghostty" "gitbutler" ];

  home-manager.users.${username} = { pkgs, ... }:
  let
    # Status line: repo, branch, context tokens, cost, lines changed, model,
    # 5-hour quota. Its dependencies are pinned onto PATH; bashOptions is
    # emptied because the script expects failed lookups (e.g. no git branch)
    # to fall through rather than abort.
    statusline = pkgs.writeShellApplication {
      name = "claude-statusline";
      runtimeInputs = with pkgs; [ jq git gawk coreutils ];
      bashOptions = [ ];
      text = builtins.readFile ./claude-statusline.sh;
    };

    # settings.json, shared by the personal and work accounts. Nix-owned, so
    # settings changed from inside Claude Code (e.g. /config) don't persist —
    # change them here and rebuild.
    claudeSettings = {
      theme = "auto";
      statusLine = {
        type = "command";
        command = "${statusline}/bin/claude-statusline";
      };
      # Play a sound whenever Claude finishes a turn, and a different one
      # when it stops to ask for permission.
      hooks.Stop = [{
        hooks = [{
          type = "command";
          command = "/usr/bin/afplay /System/Library/Sounds/Glass.aiff";
          async = true;
        }];
      }];
      hooks.Notification = [{
        matcher = "permission_prompt";
        hooks = [{
          type = "command";
          command = "/usr/bin/afplay /System/Library/Sounds/Ping.aiff";
          async = true;
        }];
      }];
    };
  in {
    # Claude Code from raw nixpkgs master (pkgs.master) — see the
    # nixpkgs-master input comment in flake.nix.
    programs.claude-code = {
      enable = true;
      package = pkgs.master.claude-code;
      settings = claudeSettings;
      # User-wide CLAUDE.md (~/.claude/CLAUDE.md). Not named CLAUDE.md in
      # the repo, or Claude Code would load it as memory for this directory.
      context = ./claude-user.md;
    };

    # Same user-wide instructions and settings for the work account
    # (claude-work, below).
    home.file.".claude-work/CLAUDE.md".source = ./claude-user.md;
    home.file.".claude-work/settings.json".text = builtins.toJSON claudeSettings;

    # Stop Claude Code self-updating into the read-only store;
    # you update it via Nix instead.
    home.sessionVariables.DISABLE_AUTOUPDATER = "1";

    # nixpkgs' wrapper defaults this to "system", which on macOS reads only
    # SSL_CERT_FILE / /etc/ssl/certs and fails every API call with
    # UNABLE_TO_GET_ISSUER_CERT_LOCALLY. Trust Bun's bundled Mozilla roots too.
    home.sessionVariables.CLAUDE_CODE_CERT_STORE = "bundled,system";

    # Work uses a separate Anthropic account; CLAUDE_CONFIG_DIR points
    # Claude Code at an isolated config/credentials dir (default is
    # ~/.claude) so logging in here doesn't clobber the personal session.
    programs.zsh.shellAliases.claude-work = "CLAUDE_CONFIG_DIR=$HOME/.claude-work claude";

    # Jump into this config repo and start a Claude Code session there.
    programs.zsh.shellAliases.ncc = "cd ~/.config/nix-darwin && claude";

    # Ghostty config. The file is Nix-owned so the first-launch auto-update
    # prompt is suppressed declaratively. Edits made in the app won't
    # persist — change this block and rebuild. Other modules append to it
    # (`text` is a lines option): modules/interface/aerospace.nix adds its
    # keybind.
    xdg.configFile."ghostty/config".text = ''
      auto-update = off
    '';

    # Programs GitButler's `but tui` can open files in. User-defined entries
    # come before the built-ins, so Helix is what `o` (open in default
    # program) uses; `O` still offers the full list. This is GitButler's own
    # program list, separate from git's core.editor. `hx` is installed by
    # modules/apps/other.nix; the store path is used here so this works
    # regardless of PATH.
    home.file."Library/Application Support/gitbutler/programs.json".text = builtins.toJSON [
      {
        id = "helix";
        name = "Helix";
        category = "editor";
        executable = {
          type = "pathExecutable";
          nameOrPath = "${pkgs.helix}/bin/hx";
          requiresTerminal = true;
        };
        openArgs = [ "{{filepath}}" ];
        openAtLineArgs = [ "{{filepath}}:{{line_number}}" ];
      }
    ];
  };
}
