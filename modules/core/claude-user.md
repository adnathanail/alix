# User-wide instructions

Applies to every project. Project CLAUDE.md files can add to or override these.

## Git

- **Do not commit without asking.**
- **Do not add attributions to yourself in commit messages.**
- Some repositories are managed with GitButler. If the current branch is `gitbutler/workspace`,
  use the `but` CLI rather than git write commands.
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
change a user-wide setting, edit `claudeSettings` in `~/.config/nix-darwin/modules/core/dev.nix`
(the status line script is `modules/core/claude-statusline.sh` there), then ask the user to
rebuild with `ns`. Project-level `.claude/settings.json` / `settings.local.json` are not managed
and can be edited as usual.
