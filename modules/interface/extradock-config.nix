# ExtraDock's docks and settings, as Nix. ExtraDock keeps its live state in
# a SQLite store (~/Library/Application Support/ExtraDock5/dockstore.sqlite)
# that isn't safe to write from outside, so this doesn't touch it. It
# builds the same `.extradock5backup` file ExtraDock's own export writes, and
# links it to ~/.config/extradock/ExtraDock.extradock5backup. Load it with
# ExtraDock's "Import Backup" after `ns` — not "Import Settings", which
# reads a bare settings JSON (also linked, as settings.json, for swapping
# the app settings without touching the docks).
#
# The format, reverse-engineered from an export (formatVersion 1): a zip of
#   manifest.json  counts + format tag
#   docks.json     { format, formatVersion, docks = [ … ] }
#   settings.json  { format, formatVersion, exportedAt, settings }
# Each dock element has a UUID and a payload: `app`, `folder`, `system`
# (trash) or `widget`. A widget's own config is a JSON string, base64'd,
# in `configJSON`. The build does that encoding, so here it's plain attrs.
#
# Element and dock UUIDs are derived from the dock name and position, so
# they stay put between builds.
{ pkgs, lib, ... }:
let
  # --- Elements -------------------------------------------------------------

  customization = {
    confirmEmpty = true;
    hideFileExtension = false;
    showCountBadge = true;
    showLabel = false;
  };

  app = bundleID: path: { app = { inherit bundleID path customization; }; };
  folder = path: { folder = { inherit path customization; }; };
  trash = {
    system.item = {
      kind = "trash";
      customization = customization // { showCountBadge = false; };
    };
  };
  widget = typeID: config: { widget = { inherit typeID config; }; };

  # Widgets
  finder = location: widget "finder" {
    clickAction = "open";
    customIconFilePath = "";
    customIconId = "";
    customPath = "";
    locationPreset = location;
    showRunningIndicator = true;
  };
  # A quarter-icon gap. `span` shrinks the cell to match.
  spacer = {
    payload = widget "spacer" { customPoints = 16; sizePreset = "Quarter"; };
    span.subCellIconMultiplier = 0.25;
  };
  # Every running app not already pinned in an enabled dock — the hidden
  # list is filled in below from the other docks' contents.
  runningApps = widget "runningapps" { gestureOverridesByBundleID = { }; };

  # Apps
  ghostty = app "com.mitchellh.ghostty" "/Applications/Ghostty.app";
  safari = app "com.apple.Safari" "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app";
  vscode = app "com.microsoft.VSCode" "/Users/adnathanail/Applications/Home Manager Apps/Visual Studio Code.app";
  gitbutler = app "com.gitbutler.app" "/Applications/GitButler.app";
  mailmate = app "com.freron.MailMate" "/Applications/MailMate.app";
  slack = app "com.tinyspeck.slackmacgap" "/Applications/Slack.app";
  mimestream = app "com.mimestream.Mimestream" "/Applications/Mimestream.app";
  whatsapp = app "net.whatsapp.WhatsApp" "/Applications/WhatsApp.app";
  spotify = app "com.spotify.client" "/Applications/Spotify.app";

  # --- Docks ----------------------------------------------------------------
  # All sit on the bottom edge. `alignment` is leading / center / trailing.

  docks = [
    {
      name = "Productivity";
      anchor.alignment = "center";
      appearance.background.glass.clear = true;
      behavior.frontmostClickAction = "minimize";
      elements = [
        (finder "Documents")
        ghostty
        safari
        spacer
        vscode
        gitbutler
        (folder "/Users/adnathanail/Downloads")
        trash
      ];
    }
    {
      name = "Comms";
      anchor.alignment = "trailing";
      appearance.background.glass.clear = true;
      elements = [ mailmate slack mimestream whatsapp ];
    }
    {
      name = "Other";
      behavior.isEnabled = false;
      behavior.badges.isEnabled = false;
      elements = [ spotify ];
    }
    {
      name = "Running apps";
      elements = [ runningApps ];
    }
  ];

  # --- Settings -------------------------------------------------------------

  # New docks' appearance; every dock above starts from this too, with no
  # edge gap (AeroSpace's bottom gap assumes 76pt bar + 0pt edge gap).
  dockAppearance = {
    background.glass.clear = false;
    barPadding = 6;
    barThickness = 76;
    barThicknessIsAutomatic = true;
    edgeGap = 8;
    effectIntensity = 1;
    effects = [ ];
    iconSize = 64;
    iconSpacing = 2;
    magnification = { falloffRadius = 96; isEnabled = false; maxScale = 1.5; };
    showRunningIndicators = true;
  };

  settings = {
    dockDefaults.appearance = dockAppearance;
    general = {
      alwaysOpaqueDockBackgrounds = false;
      appMode = "menuBarOnly";
      crashReportingEnabled = true;
      dockThemes = [ ];
      gestures = {
        clickChordsEnabled = false;
        commandClick = "revealInFinder";
        middleClick = "quit";
        optionClick = "hideShow";
        optionCommandClick = "showOnlyThisApp";
        scrollAction = "cycleWindows";
        scrollGesturesEnabled = true;
        shiftClick = "quit";
      };
      magneticSnappingDisabled = false;
      nativeDockSuppressed = false;
      respectDockSpace = false;
      respectDockSpaceActiveOnDrag = false;
      runningApps = {
        attentionStyle = "bounce";
        excludedBundleIDs = [ ];
        showRunningIndicators = true;
      };
      showManagerOnLaunch = false;
      updateChannel = "stable";
      windowPreviews = {
        appNameStyle = "default";
        bufferDistance = 12;
        captureQuality = "nominal";
        cardHeight = 187.5;
        cardWidth = 300;
        compactHideTrafficLights = false;
        compactItemSize = 2;
        compactThreshold = 0;
        compactTitleFormat = "appNameAndTitle";
        disableDockStyleTrafficLights = false;
        excludedAppNames = [ ];
        fadeOutDuration = 0.4;
        forceCompactMode = false;
        hoverDelay = 0.2;
        inactivityTimeout = 0.2;
        includeHiddenWindows = true;
        includeMinimizedWindows = true;
        isEnabled = true;
        keepOnAppTerminate = false;
        lockAspectRatio = true;
        maxColumns = 3;
        maxRows = 3;
        showAppName = true;
        showCurrentSpaceOnly = false;
        showWindowTitle = true;
        sortOrder = "mostRecentFirst";
        windowTitleFilters = [ ];
        windowTitleVisibility = "whenHoveringPreview";
      };
    };
  };

  # --- Assembly -------------------------------------------------------------

  # Every per-dock field ExtraDock exports; the docks above override bits.
  dockBase = {
    anchor = {
      alignment = "leading";
      edge = "bottom";
      fixedEdgePadding = { bottom = 0; left = 0; right = 0; top = 0; };
      floatingBasis = "physicalFrameV2";
      fullWidth = false;
      offset = 0;
    };
    appearance = dockAppearance // { edgeGap = 0; };
    behavior = {
      autohide = { hideDelay = 1; isEnabled = false; revealDelay = 0.16; };
      badges = { isEnabled = true; perApp = { }; showFullNumber = true; };
      collapse = {
        buttonPlacement = "automatic";
        handle.arrow = { };
        handleColor = { alpha = 1; blue = 1; green = 1; red = 1; };
        hoverCollapseDelay = 0.2;
        hoverExpandDelay = 0.05;
        hoverToExpand = false;
        hoverTrigger = "automatic";
        isEnabled = false;
      };
      desktopWidgetMode = false;
      dragHandleSide = "automatic";
      frontmostClickAction = "none";
      hideOnFullscreen = true;
      hotkey = { autoHideDelay = 0; isEnabled = false; };
      isEnabled = true;
      layout = "dock";
      positionLocked = false;
      respectDockSpace = true;
      showDragHandle = false;
      showOnAllScreens = false;
      showWindowlessApps = true;
      spaceBehavior = "allSpaces";
    };
    orientation = "horizontal";
    perScreenAnchors = { };
    screenAssignments = [ ];
  };

  # A stable, UUID-shaped ID from a string.
  uuid = s:
    let h = lib.toUpper (builtins.hashString "sha256" "extradock:${s}");
    in "${lib.substring 0 8 h}-${lib.substring 8 4 h}-${lib.substring 12 4 h}-${lib.substring 16 4 h}-${lib.substring 20 12 h}";

  # Elements are either a bare payload or { payload; span; }.
  mkElement = dockName: i: e:
    let e' = if e ? payload then e else { payload = e; };
    in {
      id = uuid "${dockName}/${toString i}";
      payload = e'.payload;
      span = { crossAxis = 1; mainAxis = 1; } // (e'.span or { });
    };

  # What the running-apps widget hides: whatever the enabled docks already
  # show — their apps, and Finder if one has a Finder widget.
  enabledElements = lib.concatMap (d: map (e: e.payload or e) d.elements)
    (lib.filter (d: d.behavior.isEnabled or true) docks);
  pinnedPaths =
    map (e: e.app.path) (lib.filter (e: e ? app) enabledElements)
    ++ lib.optional (lib.any (e: e.widget.typeID or null == "finder") enabledElements)
      "/System/Library/CoreServices/Finder.app";
  fillRunningApps = e:
    if e.payload.widget.typeID or null == "runningapps"
    then lib.recursiveUpdate e { payload.widget.config.hiddenItems = pinnedPaths; }
    else e;

  mkDock = d:
    lib.recursiveUpdate dockBase (removeAttrs d [ "elements" ]) // {
      id = uuid d.name;
      elements = map fillRunningApps (lib.imap0 (mkElement d.name) d.elements);
    };

  builtDocks = map mkDock docks;
  # A fixed timestamp keeps the build reproducible; ExtraDock only records it.
  exportedAt = "2000-01-01T00:00:00Z";

  json = name: value: pkgs.writeText name (builtins.toJSON value);

  docksJSON = json "docks.json" {
    format = "com.appitstudio.extradock5.docks";
    formatVersion = 1;
    docks = builtDocks;
  };
  settingsJSON = json "settings.json" {
    format = "com.appitstudio.extradock5.settings";
    formatVersion = 1;
    inherit exportedAt settings;
  };
  manifestJSON = json "manifest.json" {
    format = "com.appitstudio.extradock5.backup";
    formatVersion = 1;
    inherit exportedAt;
    dockCount = lib.length builtDocks;
    elementCount = lib.foldl' (n: d: n + lib.length d.elements) 0 builtDocks;
    iconCount = 0;
    profile = "backup";
  };

  backup = pkgs.runCommand "ExtraDock.extradock5backup" {
    nativeBuildInputs = [ pkgs.jq pkgs.zip ];
  } ''
    mkdir work && cd work
    cp ${settingsJSON} settings.json
    cp ${manifestJSON} manifest.json
    # Widget configs: attrs `config` → base64'd JSON string `configJSON`.
    jq '(.docks[].elements[].payload | select(.widget) | .widget) |=
          { typeID, configJSON: (.config | tojson | @base64) }' \
      ${docksJSON} > docks.json
    # Zip can't store dates before 1980, and the store's are 1970.
    touch -t 198001010000 *.json
    zip -X -D $out settings.json manifest.json docks.json
  '';
in {
  home.file.".config/extradock/ExtraDock.extradock5backup".source = backup;
  home.file.".config/extradock/settings.json".source = settingsJSON;
}
