# qBittorrent — torrent client. From Nix because Homebrew disabled its cask
# for failing Gatekeeper. Its in-app update check only links to the download
# page; turn it off in Preferences → Advanced.
#
# Settings are declared below and merged into
# ~/.config/qBittorrent/qBittorrent.ini on every `ns` by `qbittorrent-apply`
# (qbittorrent-apply.py) — see there for how. Change them here, not in-app:
# an in-app change to a declared key is reverted on the next rebuild.
# Undeclared settings stay app-managed.
{ pkgs, lib, ... }:
let
  # INI section → keys, named as qBittorrent writes them.
  settings = {
    BitTorrent = {
      # Download only: a torrent hits its share limit the moment it
      # finishes, and is then stopped rather than left seeding. (Uploading
      # during a download is left uncapped — peers throttle clients that
      # don't upload back, and the upload limit's 0 means unlimited anyway.)
      "Session\\GlobalMaxRatio" = 0;
      "Session\\ShareLimitAction" = "Stop";
    };
  };

  apply = pkgs.writeShellScriptBin "qbittorrent-apply" ''
    exec ${pkgs.python3}/bin/python3 ${./qbittorrent-apply.py} "$@" ${pkgs.writeText "qbittorrent-settings.json" (builtins.toJSON settings)}
  '';
in {
  home.packages = [ pkgs.qbittorrent apply ];

  # Failing shouldn't stop the rest of `ns`.
  home.activation.qbittorrentApply = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ -v DRY_RUN ]]; then
      ${apply}/bin/qbittorrent-apply --dry-run || true
    else
      ${apply}/bin/qbittorrent-apply || true
    fi
  '';
}
