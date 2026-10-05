# Burly — menu-bar link router: pick a browser profile for each link
# clicked in another app. Not in Homebrew or nixpkgs; ships as a notarized
# DMG. Its Sparkle appcast lists one versioned URL per release
# (`releases/v<version>/Burly-<version>.dmg`; the website's
# `/download/Burly.dmg` redirects to a mutable `releases/latest/`), so the
# pin uses the versioned one — bump `version` and refetch the hash
# (`nix-prefetch-url --type sha256 <url>`) together.
#
# Settings are declared below and merged in on every `ns` by `burly-apply`
# (burly-apply.py) — see there for how. Change them here, not in-app: an
# in-app change to a declared key is reverted on the next rebuild.
#
# Unpacked via `hdiutil attach` + `cp`, not `undmg`, for the same reason as
# ExtraDock (see ../extradock.nix): it bundles Sparkle, whose
# nested signatures an archive-extraction tool would invalidate.
{ pkgs, lib, ... }:
let
  version = "1.4.0";
  burly = pkgs.stdenvNoCC.mkDerivation {
    pname = "burly";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/burly-prod.firebasestorage.app/releases/v${version}/Burly-${version}.dmg";
      hash = "sha256-vieCMH10LYsD2d2QnaduT4G/t+kBeCyQOd5vBz8mreQ=";
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mnt=$(mktemp -d)
      /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$src"
      mkdir -p $out/Applications
      cp -R "$mnt/Burly.app" $out/Applications/
      /usr/bin/hdiutil detach "$mnt"
      runHook postInstall
    '';
    meta = {
      description = "Browser profile picker and link router";
      homepage = "https://www.burly.click/";
      platforms = lib.platforms.darwin;
    };
  };

  # Burly stores a petal colour as the RGB value in one integer.
  colour = hex: lib.fromHexString (lib.removePrefix "#" hex);

  # A destination's `id` is a UUID of Burly's choosing; this makes a stable
  # one from the profile name instead, so a new profile needs no `uuidgen`.
  # (`lastUsedDestinationID` points at one; Burly copes if it's stale.)
  uuid = name:
    let h = lib.toUpper (builtins.hashString "sha256" "burly:${name}");
    in lib.concatStringsSep "-" (map (r: builtins.substring r.s r.n h) [
      { s = 0; n = 8; } { s = 8; n = 4; } { s = 12; n = 4; } { s = 16; n = 4; } { s = 20; n = 12; }
    ]);

  safari = profile: {
    id = uuid profile;
    browserID = "safari";
    browserBundleIdentifier = "com.apple.Safari";
    browserDisplayName = "Safari";
    profileID = profile;
    profileDisplayName = profile;
    launchStrategy.safariProfile._0 = profile;
    isAvailable = true;
    isVisible = true;
    preferEmojiOverPhoto = false;
  };

  # Top-level keys of Burly's settings JSON, as Burly itself writes them.
  # `bypassDestinationKey` is `<bundle ID>#<profile>`.
  settings = {
    mode = "alwaysAsk";
    bypassModifier = "option";
    invertBypass = false;
    bypassDestinationKey = "com.apple.Safari#Personal";
    globalHotkeysEnabled = true;
    globalHotkeyPrefix = "hyper";
    emojiPosition = "center";
    reduceAnimations = false;
    showMenuBarIcon = true;
    launchAtLogin = true;
    demoMode = false;
    # In picker order; `sortOrder` is filled in from the position. Personal
    # (Safari's default profile, no workspace), then one per profile in
    # ../profiles.nix: its workspace number is its `hotkey` (picks it from
    # the picker, and with `globalHotkeyPrefix` from anywhere) and its
    # colour the petal's (`nodeColorHex`).
    destinations = lib.imap0 (i: d: d // { sortOrder = i; }) (
      [ (safari "Personal") ]
      ++ map (p: safari p.name // {
        hotkey = toString p.workspace;
        nodeColorHex = colour p.colour;
      }) (import ../profiles.nix)
      ++ [{
        id = uuid "Brave";
        browserID = "brave";
        browserBundleIdentifier = "com.brave.Browser";
        browserDisplayName = "Brave";
        browserExecutablePath = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser";
        profileDisplayName = "Current Profile";
        launchStrategy.browserCurrentProfile = { };
        isAvailable = true;
        isVisible = false;
        preferEmojiOverPhoto = false;
      }]
    );
  };

  apply = pkgs.writeShellScriptBin "burly-apply" ''
    exec ${pkgs.python3}/bin/python3 ${./burly-apply.py} "$@" ${pkgs.writeText "burly-settings.json" (builtins.toJSON settings)}
  '';
in {
  home.packages = [ burly apply ];

  # Skipping (exit 2) or failing shouldn't stop the rest of `ns`.
  home.activation.burlyApply = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ -v DRY_RUN ]]; then
      ${apply}/bin/burly-apply --dry-run || true
    else
      ${apply}/bin/burly-apply || true
    fi
  '';

  # The store copy is read-only, so Sparkle can't update it; stop it checking.
  targets.darwin.defaults."com.mattsenter.Burly".SUEnableAutomaticChecks = false;
}
