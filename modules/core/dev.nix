# Core dev tools: Claude Code, Ghostty, GitButler.
#
# Consumed from modules/core/default.nix as:
#     ./dev.nix
{ username, ... }: {
  # Ghostty needs Homebrew: pkgs.ghostty on Darwin is fragile (Swift/Xcode
  # toolchain). GitButler needs /Applications.
  homebrew.casks = [ "ghostty" "gitbutler" ];

  home-manager.users.${username} = { pkgs, config, ... }:
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
    # change them here and rebuild. Other modules add to
    # programs.claude-code.settings too (modules/apps/rex.nix: a SessionStart
    # hook); the work account's copy is built from the merged result.
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
    home.file.".claude-work/settings.json".text = builtins.toJSON config.programs.claude-code.settings;

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
    # come before the built-ins, in this order, so the first is what `o`
    # (open in default program) uses; `O` offers the full list. This is
    # GitButler's own program list, separate from git's core.editor. `hx` is
    # installed by modules/apps/other.nix; its store path is used so this
    # works regardless of PATH.
    #
    # "Helix in Rex split" opens the file in a Rex block below the TUI's,
    # closing when Helix quits, so the TUI stays usable alongside it.
    # REX_BLOCK (set in every Rex terminal, and passed on by the TUI) picks
    # the TUI's block as the anchor; without it Rex splits the focused block.
    # The block is labelled, and if one with that label is already in the
    # TUI's window, the file is opened in that Helix instead (Escape, then
    # `:open '<path>:<line>'` typed in one write) and the block focused, so
    # there's one editor per window and its other buffers stay open.
    # `rex` is the CLI wrapper from modules/apps/rex.nix, found on PATH.
    # Without Rex, use "Helix" from `O`, which opens in the TUI's own terminal.
    home.file."Library/Application Support/gitbutler/programs.json".text =
      let
        hx = "${pkgs.helix}/bin/hx";
        jq = "${pkgs.jq}/bin/jq";
        # Takes one arg, as GitButler passes it: `<path>` or `<path>:<line>`.
        # Paths containing a single quote won't survive the `:open` quoting.
        helixInRexSplit = pkgs.writeShellScript "helix-in-rex-split" ''
          label="helix (gitbutler)"
          if [ -n "''${REX_BLOCK:-}" ]; then
            editor=$(rex block ls --json | ${jq} -r --arg a "$REX_BLOCK" --arg l "$label" '
              (.blocks[] | select(.block_id == $a) | .window_id) as $w
              | .blocks[] | select(.window_id == $w and .label == $l) | .block_id
            ' | head -n 1)
            if [ -n "$editor" ]; then
              rex send-key -b "$editor" escape
              rex send -b "$editor" ":open '$1'"$'\r'
              exec rex block focus "$editor" >/dev/null
            fi
          fi
          exec rex run --split=below ''${REX_BLOCK:+-b "$REX_BLOCK"} --label "$label" \
            --shell=none --cwd "$PWD" -- ${hx} "$@" >/dev/null
        '';
        openArgs = [ "{{filepath}}" ];
        openAtLineArgs = [ "{{filepath}}:{{line_number}}" ];
      in
      builtins.toJSON [
        {
          id = "helix-rex";
          name = "Helix in Rex split";
          category = "editor";
          executable = {
            type = "pathExecutable";
            nameOrPath = "${helixInRexSplit}";
            requiresTerminal = false;
          };
          inherit openArgs openAtLineArgs;
        }
        {
          id = "helix";
          name = "Helix";
          category = "editor";
          executable = {
            type = "pathExecutable";
            nameOrPath = hx;
            requiresTerminal = true;
          };
          inherit openArgs openAtLineArgs;
        }
      ];
  };
}
