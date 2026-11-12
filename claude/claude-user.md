# User-wide instructions

Applies to every project. Project CLAUDE.md files can add to or override these.

## Git

- **Do not commit without asking.**
- **Do not add attributions to yourself in commit messages.**
- Some repositories are managed with GitButler. In those, use the `but` CLI rather than git write
  commands, whichever branch is checked out: with a single branch applied, GitButler checks that
  branch out directly instead of `gitbutler/workspace`. A repository is managed with GitButler if
  `test -d "$(git rev-parse --git-common-dir)/gitbutler"` succeeds (GitButler keeps its state in
  `.git/gitbutler/`; the common dir covers linked worktrees too). A session-start hook says so
  for the repository a session starts in; check any other repository before writing to it.
- If you are told to commit, make changes in new commits rather than amending existing ones, unless told otherwise.

## Writing style

When writing comments, or user facing text, write from the context of someone coming into the context cold.
Don't write as though someone has heard the conversation.
People don't need to know that something hasn't happened.

If that sort of design decision context is important, put it in the local CLAUDE.md (if it exists)

## Claude Code settings

User-level Claude Code config is managed by a nix-darwin repo at `~/.config/nix-darwin`.
`~/.claude/settings.json` (and `~/.claude-work/settings.json`) are read-only Nix store symlinks,
so don't edit them directly or via `/config`, `/statusline` or the `update-config` skill. To
change a user-wide setting, edit `claudeSettings` in `~/.config/nix-darwin/modules/core/dev.nix`,
then ask the user to
rebuild with `ns`. Project-level `.claude/settings.json` / `settings.local.json` are not managed
and can be edited as usual.

The editable parts live in that repo's `claude/` folder, linked into place, so changes there
apply without a rebuild:

- This file is `~/.config/nix-darwin/claude/claude-user.md`, shared by both accounts. Edit it there.
- Mods are kept in `~/.config/nix-darwin/claude/mods/<name>/` and load from there in both
  accounts. Edits to an existing mod reload in a running session. A new mod also needs its name
  added to the `CLAUDE_CODE_PLUGIN_DIRS` list in `modules/core/dev.nix` and a rebuild, and loads
  in sessions started after that. The status line is one of them, `statusline`.
