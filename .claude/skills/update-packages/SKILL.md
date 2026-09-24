---
name: update-packages
description: "Check for and apply package/dependency updates across this nix-darwin config — the 9 flake inputs (nixpkgs-master tracks raw master for claude-code) plus everything pinned outside the flake-lock system (ExtraDock, VS Code marketplace extensions, nx, uv tools). Use when asked to update packages, check for updates, bump pins/versions, or 'do package updates' for this repo."
---

# Update packages

Runs the full update sweep for `~/.config/nix-darwin`: check every source for a newer
version, let the user pick which to apply, apply them one at a time with confirmation
between each, then clean up. Four phases, in order — don't skip or reorder them.

## Phase 0 — working directory

All commands below assume cwd is the repo root. A session may start anywhere, so first:

```bash
cd ~/.config/nix-darwin
```

Also run `git status` before starting — stash or flag anything already dirty that isn't
yours, per standard repo hygiene. Never rebuild the system yourself (`ns` /
`darwin-rebuild switch`) — that needs `sudo`; always ask the user to run it.

## Phase 1 — check every source (read-only, no writes)

The inventory below is everything in this repo that can go stale. It has two kinds:
flake inputs (governed by `flake.lock`) and manual pins (a `version` + hash hand-edited
into a `.nix` file, with no lockfile tracking them). Check all of them before asking the
user anything — don't mutate `flake.lock` or any source file in this phase.

### Flake inputs (`flake.nix` → `inputs`)

| Input | Tracks |
|---|---|
| `nixpkgs` | `nixpkgs-26.05-darwin` branch |
| `nixpkgs-unstable` | `nixpkgs-unstable` branch |
| `nixpkgs-master` | `master` branch (used only for `claude-code`, to avoid `nixpkgs-unstable`'s channel-promotion lag) |
| `nix-darwin` | `nix-darwin-26.05` branch |
| `home-manager` | `release-26.05` branch |
| `nix-homebrew` | default branch (also carries its own `brew-src` sub-pin, which updates alongside it) |
| `homebrew-core` | default branch, `flake = false` |
| `homebrew-cask` | default branch, `flake = false` |
| `agenix` | default branch |

These are *locked revisions* of fixed branches. Moving a pinned branch itself (e.g.
`nix-darwin-26.05` → the next release) is a `flake.nix` edit, not a `nix flake update` —
and when the `nix-darwin` branch changes, also update the bootstrap command in
`docs/FIRST_USE.md` (`nix run nix-darwin/<branch>#darwin-rebuild …`),
which names the same branch and must match it.

Check each without touching the lockfile — compare the locked rev to the remote ref's
current head:

```bash
for name in nixpkgs nixpkgs-unstable nixpkgs-master nix-darwin home-manager nix-homebrew homebrew-core homebrew-cask agenix; do
  owner=$(jq -r ".nodes[\"$name\"].original.owner" flake.lock)
  repo=$(jq -r ".nodes[\"$name\"].original.repo" flake.lock)
  ref=$(jq -r ".nodes[\"$name\"].original.ref // \"HEAD\"" flake.lock)
  current=$(jq -r ".nodes[\"$name\"].locked.rev" flake.lock)
  latest=$(git ls-remote "https://github.com/$owner/$repo" "$ref" | cut -f1)
  if [ "$current" = "$latest" ]; then
    echo "$name: up to date"
  else
    echo "$name: update available ($current -> $latest)"
  fi
done
```

### Manual pins (no lockfile — hand-edited `version` + hash)

| What | Pinned in | Identity |
|---|---|---|
| ExtraDock | `modules/interface/extradock.nix` | `AppitStudio/extra-dock5-updates`, mutable `prod` release tag |
| VS Code: TikZiT | `modules/core/vscode.nix` | `alekskissinger.vstikzit` |
| VS Code: GitButler for IDE | `modules/core/vscode.nix` | `BartInTheField.gitbutler-for-ide` |
| VS Code: Highlight | `modules/core/vscode.nix` | `fabiospampinato.vscode-highlight` |
| VS Code: Nunjucks | `modules/apps/eleventy.nix` | `ronnidc.nunjucks` |
| VS Code: WASM WASI Core | `modules/apps/rocq.nix` | `ms-vscode.wasm-wasi-core` |
| VS Code: coq-lsp | `modules/apps/rocq.nix` | `ejgallego.coq-lsp` |
| VS Code: vizx | `modules/apps/rocq.nix` | `inqwire.vizx` |
| `nx` | `modules/apps/nx/nx.nix` + `modules/apps/nx/package.json` | npm package `nx` |
| uv tools | `modules/apps/uvtools.nix` | one PyPI package per entry — currently `qi` → `quantuminspire` |

Check each, read-only:

```bash
# ExtraDock — download once, read the bundled Info.plist version, don't install it
curl -sL "https://github.com/AppitStudio/extra-dock5-updates/releases/download/prod/ExtraDock.dmg" -o /tmp/extradock-check.dmg
mnt=$(mktemp -d)
hdiutil attach -nobrowse -readonly -mountpoint "$mnt" /tmp/extradock-check.dmg >/dev/null
/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$mnt/ExtraDock.app/Contents/Info.plist"
hdiutil detach "$mnt" >/dev/null
# compare the printed version to `version` in modules/interface/extradock.nix

# VS Code marketplace extensions — one call per publisher.name pair above
curl -s -X POST "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" \
  -H "Content-Type: application/json" -H "Accept: application/json;api-version=3.0-preview.1" \
  -d '{"filters":[{"criteria":[{"filterType":7,"value":"<publisher>.<name>"}]}],"flags":103}' \
  | jq -r '.results[0].extensions[0].versions[0].version'
# compare to the `version` in the relevant modules/**/*.nix file

# nx
curl -s https://registry.npmjs.org/nx/latest | jq -r .version
# compare to the "nx" version in modules/apps/nx/package.json

# each uv tool — read the current package name out of modules/apps/uvtools.nix first
curl -s https://pypi.org/pypi/<package>/json | jq -r .info.version
# compare to the ==<version> pin for that tool
```

Delete the `/tmp/extradock-check.dmg` scratch file once done with it.

Report the results as one table (source → current → latest → update available y/n)
before moving to Phase 2.

## Phase 2 — ask what to update

Only offer items that Phase 1 found an update for — don't ask about things already
current. Use `AskUserQuestion` with `multiSelect: true`, grouped sensibly (e.g. one
question for flake inputs, one for manual pins). Each question allows at most 4 options
and a call allows at most 4 questions (16 items total); if more than that have updates,
ask in a second round after the first batch is handled, or fall back to a plain
numbered list in chat and let the user reply with which ones they want.

## Phase 3 — apply, one at a time, with confirmation between each

Go through the user's selections **one item at a time**: apply it, tell the user what
changed, and wait for them to rebuild (`ns`) and confirm it worked before starting the
next one. Don't batch multiple items into one rebuild cycle — if something breaks, this
is what makes it obvious which change caused it.

**Flake input:**

```bash
nix flake update <input>
git diff flake.lock   # show the user what moved
```

If `<input>` is `nixpkgs` (stable — PyCharm comes from there), a rebuild can carry
PyCharm to a new minor version. If so, `modules/apps/pycharm/pycharm.nix`
symlinks the repo's keymap into a version-pinned path
(`~/Library/Application Support/JetBrains/PyCharm<version>/keymaps/`) — check whether the
PyCharm version changed and, if so, update that path in `pycharm.nix` too, or the keymap
silently lands in an unused directory.

If `<input>` is `nixpkgs-unstable` (SketchyBar comes from there), check whether the
SketchyBar version moved. It carries a local patch,
`modules/interface/sketchybar/layered-window-levels.patch`, against `src/bar.c`'s
`bar_order_item_windows`. If a new release no longer applies it, the build fails at
`patchPhase` — rebase the patch on the new source (keep the three-level idea: bar
background +0, brackets +1, items +2 above the configured level) and first check the
upstream changelog in case the bar-dimming-on-click bug was fixed there, in which case
drop the patch and its overlay in `modules/interface/sketchybar/default.nix`.

**ExtraDock:** re-download to get the fresh hash, then edit `version` and `hash` together
in `modules/interface/extradock.nix`:

```bash
curl -sL "https://github.com/AppitStudio/extra-dock5-updates/releases/download/prod/ExtraDock.dmg" -o /tmp/extradock-new.dmg
nix hash file --sri --type sha256 /tmp/extradock-new.dmg
```

**VS Code marketplace extension:** fetch the new vsix (note `--compressed` — the gallery
gzips the response and the raw bytes won't hash-match otherwise), hash it, edit
`version` + `sha256` together in whichever `modules/**/*.nix` file owns that extension:

```bash
curl -sL --compressed "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/<publisher>/vsextensions/<name>/<newversion>/vspackage" -o /tmp/ext.vsix
nix hash file --sri --type sha256 /tmp/ext.vsix
```

For a major-version bump, skim the changelog before applying — it's usually bundled
inside the vsix:

```bash
unzip -q /tmp/ext.vsix -d /tmp/ext-extracted
cat /tmp/ext-extracted/extension/*hangelog* 2>/dev/null
```

**nx:** edit the pin, regenerate the lockfile, get the new npm-deps hash, then update
`modules/apps/nx/nx.nix`'s `version` and `npmDepsHash` together:

```bash
# edit modules/apps/nx/package.json's "nx" version first
cd nx && npm install --package-lock-only --ignore-scripts && cd ..
nix run nixpkgs#prefetch-npm-deps -- modules/apps/nx/package-lock.json
```

Commit `modules/apps/nx/package.json`, `modules/apps/nx/package-lock.json`, and `modules/apps/nx/nx.nix` together (per
CLAUDE.md) — but only if the user asks for a commit; don't commit unprompted.

**uv tool:** just edit the `==<version>` pin in `modules/apps/uvtools.nix`. No rebuild is
strictly required — uv resolves it lazily on first invocation, cached under
`~/.cache/uv` — but still confirm with the user before moving on. For a major bump,
check the PyPI package's `pyproject.toml` (`[project.scripts]`) still exposes the same
CLI entry-point name the shim wraps, and skim its changelog/release notes.

**If a rebuild breaks:** isolate the failing derivation instead of guessing:

```bash
nix build --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  system = flake.darwinConfigurations.Alexs-MacBook-Pro;
in system.pkgs.<attribute path>
' -L
nix log <the .drv path from the error>
```

If the failure looks like an upstream regression, check whether it's known before
assuming it's something in this repo — `gh api repos/<owner>/<repo>/commits?path=<file>`
to see recent history on the relevant file, `gh search issues`/`gh search prs` in that
repo for the symptom. If it's a fresh, unfixed regression, prefer pinning just that
input to the commit right before the break over reverting the whole bump:

```bash
nix flake lock --override-input <input> github:<owner>/<repo>/<good-rev>
```

Afterwards check `flake.lock`'s `nodes.<input>.original` still points at the tracked
branch (not the pinned commit) — `--override-input` only needs to touch `locked`, so a
future `nix flake update <input>` naturally recovers once upstream fixes it.

## Phase 4 — clean up

Once every selected item is applied and confirmed:

```bash
rm -f result                 # any `nix build` result symlink left in the repo root
rm -rf /tmp/extradock-*.dmg /tmp/ext*.vsix /tmp/ext-extracted   # scratch downloads
git status                   # final review — confirm only the intended files changed
```

Do not commit unless the user asks. If they do, follow CLAUDE.md's commit rules (new
commits, no self-attribution, use `but` if on `gitbutler/workspace`).

## Running this from outside the repo

If a session starts in another directory, `cd ~/.config/nix-darwin` first (Phase 0)
before running any check or apply command — every path in this skill is repo-relative.
Nothing else about the process changes based on where the session started.

## Maintenance note (for Claude, not the user)

The inventory tables above are a snapshot of what's pinned in this repo as of writing.
**If a new `modules/**/*.nix` module is added with its own manually-pinned dependency** — a
`fetchurl` with a hash, another `vscode-utils.extensionFromVscodeMarketplace` call, a
new uv-tool entry, or any other hand-pinned version — add it to the Phase 1 manual-pins
table the next time this skill is touched. This skill is only as good as its last sync
with the repo; don't let it silently go stale.
