# Rex Beta — preview build, not in Homebrew or nixpkgs. The download location
# isn't public, so it lives in nix-private (rex/base-url, see `privateDir` in
# flake.nix) and this module pins only the DMG's name and hash. Nix can't read
# that file during a pure build, so `requireFile` expects the DMG to be in the
# store already, and fails with the command that puts it there. That can come
# up again after a garbage collection, if something forces a rebuild.
#
# <base-url>/appcast.xml is the app's Sparkle feed, listing one
# `Rex-<version>-<build>.dmg` per build. Bump `version`, `build` and `hash`
# together (`nix hash file --sri --type sha256 <dmg>`).
#
# The feed only keeps recent builds. If this one has gone, a copy of the same
# DMG can be added directly, as long as it's named to match:
#     nix-store --add-fixed sha256 Rex-<version>-<build>.dmg
#
# Copied straight off a live `hdiutil` mount, for the same reason as ExtraDock
# (see ../interface/extradock.nix): it bundles Sparkle, whose nested signatures
# an archive-extraction tool would invalidate.
#
# Consumed from modules/apps/default.nix as:
#     ./rex.nix
{ username, privateDir, pkgs, lib, ... }:
let
  version = "0.1.0";
  build = "1829";
  dmg = "Rex-${version}-${build}.dmg";
  rex = pkgs.stdenvNoCC.mkDerivation {
    pname = "rex-beta";
    version = "${version}-${build}";
    src = pkgs.requireFile {
      name = dmg;
      hash = "sha256-+LAJifflXE36y8Go5Xa/RIgEmEkceSTMnIShPKrbv0k=";
      message = ''
        ${dmg} isn't in the Nix store. Add it, then rebuild:
          nix-prefetch-url --name ${dmg} "$(cat ${privateDir}/rex/base-url)/${dmg}"
      '';
    };
    dontUnpack = true;
    # The signed app ships a dangling Sparkle.framework/XPCServices symlink,
    # and removing it would break the signature.
    dontCheckForBrokenSymlinks = true;
    installPhase = ''
      runHook preInstall
      mnt=$(mktemp -d)
      /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$src"
      mkdir -p $out/Applications
      cp -R "$mnt/Rex Beta.app" $out/Applications/
      /usr/bin/hdiutil detach "$mnt"
      runHook postInstall
    '';
    meta = {
      description = "Rex (preview channel)";
      platforms = lib.platforms.darwin;
    };
  };

  # The `rex` CLI. The app installs its server, which is also the CLI, under
  # Application Support on first launch and runs it from `Versions/Current`, so
  # this runs that copy and always matches the running server's version.
  rexCli = pkgs.writeShellScriptBin "rex" ''
    cli="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
    if [ ! -x "$cli" ]; then
      echo "rex: $cli is missing; open Rex Beta once to install it" >&2
      exit 1
    fi
    exec "$cli" "$@"
  '';

  rexSkill = ''
    ---
    name: rex
    description: Use the rex CLI to manage Rex sessions, open tabs, arrange panes, run commands, inspect terminal output, and control connected Rex apps.
    metadata:
      rex-stub: "2"
    ---

    Run `rex __internal skill --feature-session-naming=false` and follow the guide it prints. The guide comes from
    the installed Rex CLI, so it describes the commands available in that version.

    If the command fails, the installed Rex version predates the guide. Start with
    `rex whoami --json`, then use `rex --help` and `rex COMMAND --help`.
  '';
in {
  home-manager.users.${username} = {
    home.packages = [ rex rexCli ];

    # Rex's agent skill and session-start hook, as `rex skill setup` would
    # install them; that command can't write the Nix-owned settings.json.
    # Both are stubs that ask the installed CLI for their text, so they keep
    # up with Rex versions. The hook tells Claude which Rex session and
    # terminal it's in (silent outside Rex). Compare with what the current
    # Rex would install after an update:
    #     CLAUDE_CONFIG_DIR=$(mktemp -d) rex skill setup --agent claude
    programs.claude-code.skills.rex = rexSkill;
    home.file.".claude-work/skills/rex/SKILL.md".text = rexSkill;
    programs.claude-code.settings.hooks.SessionStart = [{
      hooks = [{
        type = "command";
        command = "/bin/sh -c '${rexCli}/bin/rex __internal session-start --agent claude --feature-session-naming=false 2>/dev/null || true'";
        timeout = 5;
      }];
    }];

    # Rex's config file: key bindings layered over the app's built-in ones.
    # `rex config check` validates it; `rex keymap` shows the resolved keys.
    # Rex has no API for custom GUI buttons; custom actions appear in the
    # command palette and can be bound to keys.
    xdg.configFile."rex/init.lua".text = ''
      rex.unbind("cmd+n")

      -- The focused pane's directory, from its foreground process: zsh
      -- doesn't report its working directory to the terminal, so the
      -- terminal's `pwd` is empty.
      local function pane_dir(ctx)
        local p, err = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
        if p == nil then error(err, 0) end
        local dir = p.foreground and p.foreground.cwd
        if dir == nil then error("can't tell this pane's directory", 0) end
        return dir
      end

      -- Runs argv in dir, failing the action with the command's stderr.
      local function run_in(dir, argv)
        local r, err = rex.exec(argv, { cwd = dir, timeout = 20 })
        if r == nil then error(err, 0) end
        if not r.ok then error(r.stderr, 0) end
        return r.stdout
      end

      local bin = "/etc/profiles/per-user/${username}/bin/"

      -- Open the GitButler app on the focused pane's directory.
      rex.action{
        name     = "gitbutler_gui",
        title    = "Open GitButler Here",
        keywords = "but git",
        run = function(ctx)
          run_in(pane_dir(ctx), { "/opt/homebrew/bin/but", "gui" })
        end,
      }
      rex.bind("cmd+b", "gitbutler_gui")

      -- Open the root of the focused pane's git repository in VS Code.
      rex.action{
        name     = "vscode_repo",
        title    = "Open Repository in VS Code",
        keywords = "code git root",
        run = function(ctx)
          local r = rex.exec({ bin .. "git", "rev-parse", "--show-toplevel" }, { cwd = pane_dir(ctx), timeout = 5 })
          if r == nil or not r.ok then error("not in a git repository", 0) end
          local root = r.stdout:gsub("%s+$", "")
          run_in(root, { bin .. "code", root })
        end,
      }
      rex.bind("cmd+o", "vscode_repo")
    '';
  };

  # The store copy is read-only, so Sparkle can't update it; stop it checking.
  system.defaults.CustomUserPreferences."com.superlogical.rex".SUEnableAutomaticChecks = false;
}
