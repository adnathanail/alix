# DavMail: a local IMAP/SMTP gateway fronting Microsoft 365 over Graph.
#
# Why this exists: the work tenant only permits approved mail clients, so
# MailMate cannot talk to Exchange directly. DavMail authenticates as its own
# registered Entra application and re-exposes the mailbox on loopback as
# ordinary IMAP/SMTP, which MailMate can speak.
#
# **This requires the tenant's blessing.** DavMail's own application id
# (facd6cff-a294-4415-b59f-c5b01937d7bd) needs admin consent in the tenant
# before any of it works. Without consent, sign-in dies at the device-code
# step and there is nothing to debug on this side. Note DavMail authenticates
# *as itself* — it does not borrow Outlook's client id — which is what makes
# it something IT can actually approve and audit in the sign-in logs.
#
# Consumed from flake.nix as:
#     (import ./extra/davmail.nix { inherit username; })
{ username }:

{ pkgs, ... }:

let
  stateDir = "/Users/${username}/.local/state/davmail";
  logDir = "/Users/${username}/Library/Logs";

  # Pure config, no credentials, so it lives in the store rather than agenix.
  # The OAuth refresh token is the only real secret and it is deliberately
  # kept out of here by davmail.oauth.tokenFilePath below — with that unset
  # DavMail persists the token *into this properties file*, which a read-only
  # store path cannot accept.
  settings = pkgs.writeText "davmail.properties" ''
    # Headless is not a preference, it is the only option: the nixpkgs build
    # bundles only the gtk-linux and win32 SWT jars (no cocoa-macosx), so
    # every GUI code path is a hard failure on darwin.
    davmail.server=true
    davmail.enableTray=false

    # Graph, not EWS — Microsoft retires EWS for M365 in October 2026.
    # NB: this is the *transport*, independent of the authentication flow
    # below. They are separate settings that happen to share a prefix.
    davmail.mode=O365EWS

    davmail.oauth.clientId=d3590ed6-52b3-4102-aeff-aad2292ab01c

    # Authorization-code flow, driven manually.
    #
    # Not the first choice: device code (O365DeviceCode) is the natural fit
    # for a headless agent, but this tenant's Conditional Access blocks the
    # device code flow outright — sign-in succeeds and then token issuance is
    # refused with "does not meet the criteria to access this resource".
    # O365Interactive is not an option either: it wants an SWT browser window
    # and the nixpkgs build has no macOS SWT (see above).
    #
    # O365Manual prints a login URL, you authenticate in a real browser, and
    # paste the resulting redirect URL back on stdin. A launchd agent has no
    # stdin, so this cannot complete under the agent — that is what the
    # `davmail-auth` helper below is for. Once a refresh token exists in the
    # token file DavMail authenticates from it and never prompts, so the
    # agent only needs this setting for the rare re-auth.
    davmail.authentication=O365Manual

    # Tenant is left at the default ("common", the multi-tenant authority).
    # If sign-in fails with "Invalid domain name - No tenant-identifying
    # information found", the tenant requires its own authority: add
    # davmail.oauth.tenantId=<guid>. That guid identifies the employer, so
    # at that point this file should move to agenix like the MailMate ones.

    # Loopback only. These ports front a live mailbox, so keep them off the
    # LAN: an explicit bind address *and* allowRemote=false.
    davmail.bindAddress=127.0.0.1
    davmail.allowRemote=false
    davmail.imapPort=1143
    davmail.smtpPort=1025
    # 0 disables. Mail only — no calendar, contacts or directory.
    davmail.caldavPort=0
    davmail.ldapPort=0
    davmail.popPort=0

    # Refresh token: encrypted, 0600, outside the store and outside this file.
    davmail.oauth.tokenFilePath=${stateDir}/token

    # Repo rule: never let a tool update itself, the store is read-only.
    davmail.disableUpdateCheck=true

    # Note the first-run device code does NOT come through log4j at all — it
    # is printed to stdout, so it lands in the launchd StandardOutPath file
    # below rather than here. INFO is kept anyway for connection tracing.
    davmail.logFilePath=${logDir}/davmail.log
    davmail.logFileSize=1MB
    log4j.logger.davmail=INFO
  '';
in
{
  environment.systemPackages = [
    pkgs.davmail

    # One-time sign-in helper (and the way back after a token expires).
    #
    # O365Manual needs a console to paste the redirect URL into, and the
    # launchd agent has neither stdin nor, while it is running, free ports.
    # So: stop the agent, run DavMail in the foreground against the *same*
    # settings file (so the token lands at the same tokenFilePath the agent
    # reads), and put the agent back on the way out.
    (pkgs.writeShellScriptBin "davmail-auth" ''
      set -euo pipefail
      plist="$HOME/Library/LaunchAgents/org.nixos.davmail.plist"

      restart() {
        echo
        echo "Restarting the DavMail agent..."
        launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null || true
      }

      echo "Stopping the DavMail agent so it releases ports 1143/1025..."
      launchctl bootout "gui/$(id -u)/org.nixos.davmail" 2>/dev/null || true
      # Only arm the restart once the agent is actually down, so a failure
      # above cannot leave us bootstrapping a service that never stopped.
      trap restart EXIT

      echo
      echo "DavMail is starting in the foreground."
      echo
      echo "In ANOTHER terminal, trigger authentication:"
      echo
      echo "    nc 127.0.0.1 1143"
      echo "    a LOGIN you@work-domain x"
      echo
      echo "(the password is ignored with this flow)."
      echo
      echo "A login URL will appear below. Open it in your browser and sign in;"
      echo "you will land on a blank page. Copy that blank page's FULL url and"
      echo "paste it here, then press Enter."
      echo
      echo "Ctrl-C once the LOGIN returns \"a OK\"."
      echo

      # Deliberately not exec: the EXIT trap has to survive to restart the agent.
      ${pkgs.davmail}/bin/davmail ${settings}
    '')
  ];

  # DavMail writes the token file itself with 0600 but will not create the
  # directory tree above it.
  system.activationScripts.postActivation.text = ''
    install -d -m 700 -o ${username} -g staff "${stateDir}"
    install -d -m 755 -o ${username} -g staff "${logDir}"
  '';

  launchd.user.agents.davmail = {
    serviceConfig = {
      ProgramArguments = [ "${pkgs.davmail}/bin/davmail" "${settings}" ];
      RunAtLoad = true;
      KeepAlive = true;
      # DavMail's own log4j file above is the useful one; these two only
      # catch failures early enough that logging isn't up yet.
      StandardOutPath = "${logDir}/davmail.launchd.out.log";
      StandardErrorPath = "${logDir}/davmail.launchd.err.log";
    };
  };
}
