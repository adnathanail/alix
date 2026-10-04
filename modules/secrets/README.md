# Secrets management (agenix)

Encrypted secrets are in `agefiles/` and are safe to commit. Their recipients are in
`secrets.nix`, which the `agenix` CLI reads from the current directory, so run `agenix` from
this directory (`modules/secrets/`) and name files as `agefiles/<name>.age`.

- Env vars: `$NPM_FONT_AWESOME_TOKEN`, `$NPM_GITHUB_PACKAGES_TOKEN`.
- SketchyBar / aerospace-swipe code-signing identity: `alix-local-signing-identity` (a `.p12` of a self-signed codeSigning cert + key; the password is `nix-darwin`, and it's only meaningful inside agenix)

Config that's private but not secret (MailMate's account plists, clonager's config) isn't
here. It's plain text in the private `nix-private` repo, checked out at `~/.config/nix-private`;
see *Private config in nix-private* in `CLAUDE.md`. Use agenix only for actual credentials.

- *First use on a brand-new key* (once ever):
    1. `mkdir -p ~/.config/age && age-keygen -o ~/.config/age/keys.txt`
    2. Back the key up to 1Password:
        `op document create ~/.config/age/keys.txt --title "nix-darwin age key" --vault Private`
        (rotate the item with `op document edit "nix-darwin age key" ~/.config/age/keys.txt`
        if you regenerate the key later).
    3. `age-keygen -y ~/.config/age/keys.txt` and paste the `age1...`
        output into `modules/secrets/secrets.nix` in place of the placeholder.
    4. For each secret listed in `modules/secrets/secrets.nix`, run
        `cd modules/secrets && EDITOR=vim agenix -e agefiles/<name>.age`. `git add` the
        `.age` file so the flake sees it.
    5. `ns` — secrets decrypt to `/run/agenix/<name>`, and the env-var ones are exported
        in the shell via `~/.config/nix-secrets.env` (see `envvars.nix`).
- *First use on a fresh machine* (key already in 1Password): enable `modules/core` first —
    it installs 1Password, `op` and `nix-restore-age-key` — then sign into 1Password, turn on
    Settings → Developer → **Integrate with 1Password CLI**, run `nix-restore-age-key` (pulls
    the key to `~/.config/age/keys.txt`, mode 0600), and only then enable `modules/secrets`.
    Full steps in [docs/FIRST_USE.md](../../docs/FIRST_USE.md).
- Shared machinery is in `modules/secrets/agenix.nix`; **secrets live with whatever uses them** —
  `modules/secrets/envvars.nix` for shell tokens, `modules/interface/sketchybar/default.nix` for the
  signing identity. Add another secret:
    1. Declare `age.secrets.<name>` in the module that consumes it (a new
        `modules/apps/<feature>.nix` if it's a new feature — add it to `modules/apps/default.nix`).
    2. Add it to `modules/secrets/secrets.nix` — that file is read by the `agenix` CLI, so it stays
        one flat list regardless of which module uses the secret.
    3. `cd modules/secrets && agenix -e agefiles/<name>.age -i ~/.config/age/keys.txt < plaintext`,
        then `git add` it. Flakes only see git-tracked files, so an unstaged `.age`
        is invisible to `ns`.
    4. If you want it as a shell env var, add a
        `write <VAR> /run/agenix/<name>` line to
        `system.activationScripts.postActivation` in
        `modules/secrets/envvars.nix` — the value lands in
        `~/.config/nix-secrets.env` on rebuild.
    5. `ns`.
