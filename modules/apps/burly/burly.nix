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
# ExtraDock (see ../../interface/extradock.nix): it bundles Sparkle, whose
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

  safari = sortOrder: id: profile: {
    inherit id sortOrder;
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
  # Destination `id`s are Burly's own UUIDs (they're what
  # `lastUsedDestinationID` points at); a new one just needs a fresh
  # `uuidgen`. `bypassDestinationKey` is `<bundle ID>#<profile>`.
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
    destinations = [
      (safari 0 "DD1369EE-A1B5-45EC-BF55-F0B9F2F948DA" "Personal")
      (safari 1 "5261B500-BC89-4708-9454-6A6EC10A00A1" "ASAC")
      (safari 4 "A733FFD8-4528-48DA-959D-57D303DD9465" "Fermioniq")
    ];
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
