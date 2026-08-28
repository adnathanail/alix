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
    davmail.mode=O365Graph

    # Device-code flow, for the same headless reason. O365Interactive wants
    # an SWT browser window that cannot exist here; O365Manual wants a
    # console this launchd agent does not have. Device code writes a URL and
    # a short code to the log, which you complete in a real browser once.
    davmail.authentication=O365DeviceCode

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
  environment.systemPackages = [ pkgs.davmail ];

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
