# eduroam at the University of Amsterdam, as a macOS configuration profile.
#
# The settings mirror what UvA's SecureW2 JoinNow installer
# (cloud.securew2.com/public/40655/uva/) writes: PEAP / MSCHAPv2 with the
# UvAnetID and its password, outer identity anonymous@uva.nl, and the
# RADIUS server's certificate pinned to the name radius.uva.nl, issued
# under one of two Sectigo roots.
#
# Everything user-specific comes from the nix-private checkout at runtime,
# under ${privateDir}/eduroam/:
#   username                     the UvAnetID, one line, e.g. abc123@uva.nl
#   usertrust-rsa-ca.pem         USERTrust RSA Certification Authority
#   sectigo-server-root-r46.pem  Sectigo Public Server Authentication Root R46
# Both roots ship in macOS's own trust store (export with `security
# find-certificate -p -c <name>
# /System/Library/Keychains/SystemRootCertificates.keychain`); their SHA-1
# fingerprints should match the installer's: 2B8F1B57… and AD98F9F3….
# The password never touches this config: macOS asks for it on the first
# join and keeps it in the Keychain.
#
# macOS won't let a script install a profile, so activation renders it to
# ~/.local/share/eduroam/eduroam.mobileconfig and opens it, which queues it
# in System Settings → General → Device Management for one click of
# Install. It's reopened only while the installed copy is missing or out
# of date (its PayloadUUID is a hash of the template and the private files).
#
# Consumed from modules/apps/default.nix as:
#     ./eduroam.nix
{ pkgs, lib, username, privateDir, ... }:
let
  eduroamDir = "${privateDir}/eduroam";

  certs = [
    { name = "USERTrust RSA Certification Authority";
      file = "usertrust-rsa-ca.pem";
      placeholder = "@CERT_USERTRUST@";
      uuid = "890BBD0E-F7F5-466B-9828-74369CE963CB"; }
    { name = "Sectigo Public Server Authentication Root R46";
      file = "sectigo-server-root-r46.pem";
      placeholder = "@CERT_SECTIGO@";
      uuid = "317D04E0-02E1-454E-AD22-BE3C005A2A27"; }
  ];

  certPayload = c: ''
    <dict>
      <key>PayloadType</key><string>com.apple.security.root</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadIdentifier</key><string>nl.uva.eduroam.cert.${c.uuid}</string>
      <key>PayloadUUID</key><string>${c.uuid}</string>
      <key>PayloadDisplayName</key><string>${c.name}</string>
      <key>PayloadCertificateFileName</key><string>${c.file}</string>
      <key>PayloadContent</key><data>${c.placeholder}</data>
    </dict>
  '';

  # @USERNAME@, @PROFILE_UUID@ and each cert's placeholder are filled in at
  # activation.
  template = pkgs.writeText "eduroam.mobileconfig.in" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>PayloadType</key><string>Configuration</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadIdentifier</key><string>nl.uva.eduroam</string>
      <key>PayloadUUID</key><string>@PROFILE_UUID@</string>
      <key>PayloadDisplayName</key><string>eduroam (UvA)</string>
      <key>PayloadDescription</key><string>Wi-Fi settings for eduroam at the University of Amsterdam.</string>
      <key>PayloadContent</key>
      <array>
        ${lib.concatMapStrings certPayload certs}
        <dict>
          <key>PayloadType</key><string>com.apple.wifi.managed</string>
          <key>PayloadVersion</key><integer>1</integer>
          <key>PayloadIdentifier</key><string>nl.uva.eduroam.wifi</string>
          <key>PayloadUUID</key><string>3E7B3278-1EE2-441B-98D5-DCC9317C9FC0</string>
          <key>PayloadDisplayName</key><string>eduroam</string>
          <key>SSID_STR</key><string>eduroam</string>
          <key>HIDDEN_NETWORK</key><false/>
          <key>AutoJoin</key><true/>
          <key>EncryptionType</key><string>WPA2</string>
          <key>EAPClientConfiguration</key>
          <dict>
            <key>AcceptEAPTypes</key><array><integer>25</integer></array>
            <key>UserName</key><string>@USERNAME@</string>
            <key>OuterIdentity</key><string>anonymous@uva.nl</string>
            <key>TLSTrustedServerNames</key><array><string>radius.uva.nl</string></array>
            <key>PayloadCertificateAnchorUUID</key>
            <array>${lib.concatMapStrings (c: "<string>${c.uuid}</string>") certs}</array>
          </dict>
        </dict>
      </array>
    </dict>
    </plist>
  '';

  privateFiles = lib.escapeShellArgs
    ([ "${eduroamDir}/username" ] ++ map (c: "${eduroamDir}/${c.file}") certs);
in
{
  system.activationScripts.postActivation.text = ''
    eduroam_dest="/Users/${username}/.local/share/eduroam"
    eduroam_missing=""
    for f in ${privateFiles}; do [ -r "$f" ] || eduroam_missing="$eduroam_missing $f"; done
    if [ -n "$eduroam_missing" ]; then
      echo "eduroam: missing$eduroam_missing; skipping profile" >&2
    else
      eduroam_user=$(tr -d '[:space:]' < "${eduroamDir}/username")
      if ! printf '%s' "$eduroam_user" | grep -Eq '^[A-Za-z0-9._-]+@uva\.nl$'; then
        echo "eduroam: ${eduroamDir}/username should hold a UvAnetID like abc123@uva.nl; skipping profile" >&2
      else
        eduroam_uuid=$(cat ${template} ${privateFiles} | shasum -a 256 | tr a-f A-F \
          | sed -E 's/^(.{8})(.{4})(.{4})(.{4})(.{12}).*/\1-\2-\3-\4-\5/')
        # Captured rather than piped into grep: activation runs under
        # pipefail, so `profiles` exiting non-zero (or grep -q closing the
        # pipe early) would read as "not installed".
        eduroam_installed=$({ profiles show -all; profiles show -user ${username}; } 2>/dev/null || true)
        if [[ "$eduroam_installed" != *"$eduroam_uuid"* ]]; then
          install -d -m 700 -o ${username} -g staff "$eduroam_dest"
          # A PEM certificate's body is the base64 DER a profile's <data> wants.
          sed -e "s|@USERNAME@|$eduroam_user|" -e "s|@PROFILE_UUID@|$eduroam_uuid|" \
            ${lib.concatMapStringsSep " " (c: ''-e "s|${c.placeholder}|$(sed '/^-----/d' "${eduroamDir}/${c.file}" | tr -d '\n')|"'') certs} \
            ${template} > "$eduroam_dest/eduroam.mobileconfig"
          chown ${username}:staff "$eduroam_dest/eduroam.mobileconfig"
          chmod 600 "$eduroam_dest/eduroam.mobileconfig"
          launchctl asuser "$(id -u -- ${username})" \
            sudo --user=${username} -- open "$eduroam_dest/eduroam.mobileconfig"
          echo "eduroam: profile queued; install it in System Settings → General → Device Management"
        fi
      fi
    fi
  '';
}
