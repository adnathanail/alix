# Everything MailMate: the cask, the account config secrets, and the
# activation step that provisions them on a fresh machine.
#
# Depends on agenix.nix for the agenix module + age identity.
# `homebrew.casks` is a listOf and `activationScripts.<name>.text` is
# types.lines, so both merge with what other modules declare — this file
# adds to them rather than owning them outright.
#
# Consumed from flake.nix as:
#     (import ./extra/mailmate.nix { inherit username; })
#
# See CLAUDE.md → "Per-tool notes" → MailMate for the Outlook.com/Hotmail
# host-pairing trap, which is the thing most likely to bite here.
{ username }:

{ ... }: {
  # 2.0 beta. The cask isn't `auto_updates` and carries `sha256 :no_check`
  # against a rolling MailMateBeta.tbz, so `brew upgrade --cask mailmate@beta`
  # pulls whatever the current beta is.
  homebrew.casks = [ "mailmate@beta" ];

  # Account config. Not secret in the cryptographic sense — OAuth tokens
  # live in the login Keychain, never in these files — but they carry a
  # personal email address and this repo is public.
  age.secrets.mailmate-sources = {
    file = ../secrets/mailmate-sources.age;
    owner = username;
    mode = "0400";
  };
  age.secrets.mailmate-identities = {
    file = ../secrets/mailmate-identities.age;
    owner = username;
    mode = "0400";
  };
  age.secrets.mailmate-submission = {
    file = ../secrets/mailmate-submission.age;
    owner = username;
    mode = "0400";
  };

  # Provision-once, not manage-forever.
  #
  # MailMate rewrites Sources/Identities/Submission.plist on launch, so a
  # read-only home.file symlink (the pycharm/custom-keymap.xml pattern)
  # would fight it. We only install a file that isn't already there: on a
  # fresh machine this bootstraps the account, and thereafter MailMate owns
  # them. To adopt settings changed in the GUI, re-encrypt from the live
  # files — the loop is in the README.
  #
  # This gets you the account definition, not a working mailbox: the OAuth
  # tokens are in the Keychain, so a new machine still needs one browser
  # sign-in. What it preserves is the host pairing MailMate's own setup
  # wizard gets wrong (both sides must be *.office365.com).
  system.activationScripts.postActivation.text = ''
    mmdir="/Users/${username}/Library/Application Support/MailMate"
    install -d -m 700 -o ${username} -g staff "$mmdir"
    provision_mailmate() {
      # $1 = name under /run/agenix, $2 = destination basename
      if [ -r "/run/agenix/$1" ] && [ ! -e "$mmdir/$2" ]; then
        install -m 600 -o ${username} -g staff "/run/agenix/$1" "$mmdir/$2"
        echo "mailmate: provisioned $2"
      fi
    }
    provision_mailmate mailmate-sources    Sources.plist
    provision_mailmate mailmate-identities Identities.plist
    provision_mailmate mailmate-submission Submission.plist
  '';

  # Settings are ordinary defaults (com.freron.MailMate is non-sandboxed) and
  # would go here as `system.defaults.CustomUserPreferences."com.freron.MailMate"`.
  # Nothing is declared yet — pick keys deliberately from MailMate's hidden
  # preferences rather than harvesting the plist, which is mostly window
  # frames and column widths. Quit MailMate before `ns` if you add any: it
  # holds prefs in memory and flushes on quit, clobbering activation's writes.
}
