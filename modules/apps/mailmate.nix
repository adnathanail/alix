# Everything MailMate: the cask, the account config, and the activation
# step that provisions it on a fresh machine.
#
# The account config lives in the private nix-private checkout
# (mailmate/*.plist; see `privateDir` in flake.nix). Not secret in the
# cryptographic sense — OAuth tokens live in the login Keychain, never in
# these files — but they carry a personal email address and this repo is
# public.
#
# `homebrew.casks` is a listOf and `activationScripts.<name>.text` is
# types.lines, so both merge with what other modules declare — this file
# adds to them rather than owning them outright.
#
# Consumed from modules/apps/default.nix as:
#     ./mailmate.nix
#
# See CLAUDE.md → "Per-tool notes" → MailMate for the Outlook.com/Hotmail
# host-pairing trap, which is the thing most likely to bite here.
{ username, privateDir, ... }: {
  # 2.0 beta. The cask isn't `auto_updates` and carries `sha256 :no_check`
  # against a rolling MailMateBeta.tbz, so `brew upgrade --cask mailmate@beta`
  # pulls whatever the current beta is.
  homebrew.casks = [ "mailmate@beta" ];

  # Provision-once, not manage-forever.
  #
  # MailMate rewrites Sources/Identities/Submission.plist on launch, so a
  # read-only home.file symlink (the modules/apps/pycharm/custom-keymap.xml pattern)
  # would fight it. We only install a file that isn't already there: on a
  # fresh machine this bootstraps the account, and thereafter MailMate owns
  # them. To adopt settings changed in the GUI, copy the live files back
  # into nix-private and commit there.
  #
  # This gets you the account definition, not a working mailbox: the OAuth
  # tokens are in the Keychain, so a new machine still needs one browser
  # sign-in. What it preserves is the host pairing MailMate's own setup
  # wizard gets wrong (both sides must be *.office365.com).
  system.activationScripts.postActivation.text = ''
    mmdir="/Users/${username}/Library/Application Support/MailMate"
    install -d -m 700 -o ${username} -g staff "$mmdir"
    for f in Sources Identities Submission; do
      src="${privateDir}/mailmate/$f.plist"
      if [ -r "$src" ] && [ ! -e "$mmdir/$f.plist" ]; then
        install -m 600 -o ${username} -g staff "$src" "$mmdir/$f.plist"
        echo "mailmate: provisioned $f.plist"
      fi
    done
  '';

  # Settings are ordinary defaults (com.freron.MailMate is non-sandboxed).
  # Pick keys deliberately from MailMate's hidden preferences rather than
  # harvesting the plist, which is mostly window frames and column widths.
  # Quit MailMate before `ns` when changing these: it holds prefs in memory
  # and flushes on quit, clobbering activation's writes.
  system.defaults.CustomUserPreferences."com.freron.MailMate" = {
    # The Dock icon's corner counters (Settings → Counters). The values are
    # MailMate's own: strings, "yes" included.
    #
    # Only the unread counter is shown in the menu bar, and that's load-
    # bearing: Hammerspoon reads the unread count from it
    # (modules/interface/hammerspoon/notifications.lua), and MailMate's
    # menu-bar items carry nothing but their number. With a second one
    # there, they can't be told apart — and an empty counter drops out, so
    # neither can their order.
    MmCounters2 = [
      { color = "systemBlueColor"; count = "unreplied"; position = "topLeft"; set = "INBOX"; }
      {
        color = "#E62124FF";
        count = "unread";
        inDock = "yes";
        inMenuBar = "yes";
        position = "topRight";
        set = "INBOX";
        soundPath = "/System/Library/Sounds/Glass.aiff";
      }
      { color = "systemYellowColor"; count = "all"; position = "bottomLeft"; }
      { color = "systemGreenColor"; count = "flagged"; inDock = "yes"; position = "bottomRight"; set = "INBOX"; }
    ];
  };
}
