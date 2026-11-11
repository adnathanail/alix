# Per-keyboard modifier remapping, for external keyboards with a Windows
# layout: the key in the Command position (Alt) becomes ⌘ and the key in
# the Option position (Windows) becomes ⌥. The built-in keyboard and any
# other keyboard are untouched, and apps see ordinary ⌘/⌥, so no
# shortcuts need rebinding.
#
# This is the same setting as System Settings → Keyboard → Keyboard
# Shortcuts → Modifier Keys with that keyboard picked in the "Select
# keyboard" menu. macOS stores it per device in the ByHost global domain
# under `com.apple.keyboard.modifiermapping.<vendor>-<product>-0` and
# reapplies it whenever the keyboard is plugged in. `hidutil` applies it
# straight away to a keyboard that's already connected, without a replug.
#
# To add a keyboard, find its IDs with `hidutil list --matching keyboard`
# (the VendorID/ProductID columns, in hex).
#
# Consumed from modules/core/default.nix as:
#     ./keyboards.nix
{ lib, username, ... }:
let
  # HID usage IDs (usage page 7, keyboard), as macOS's modifier mapping
  # expects them: 0x700000000 + usage.
  key = {
    leftAlt = 30064771298; # 0x7000000E2
    leftGui = 30064771299; # 0x7000000E3 (Windows / ⌘)
    rightAlt = 30064771302; # 0x7000000E6
    rightGui = 30064771303; # 0x7000000E7
  };

  # Alt ↔ Windows, on both sides.
  windowsLayoutSwap = [
    { src = key.leftAlt; dst = key.leftGui; }
    { src = key.leftGui; dst = key.leftAlt; }
    { src = key.rightAlt; dst = key.rightGui; }
    { src = key.rightGui; dst = key.rightAlt; }
  ];

  keyboards = [
    {
      name = "Razer BlackWidow Lite";
      vendorId = 5426; # 0x1532
      productId = 565; # 0x235
      mapping = windowsLayoutSwap;
    }
  ];

  # `defaults write` can't build an array of dicts from -array/-dict
  # arguments, so the value is passed as an XML plist fragment, which keeps
  # the integer types.
  defaultsXml = mapping: "<array>" + lib.concatMapStrings (m:
    "<dict>"
    + "<key>HIDKeyboardModifierMappingSrc</key><integer>${toString m.src}</integer>"
    + "<key>HIDKeyboardModifierMappingDst</key><integer>${toString m.dst}</integer>"
    + "</dict>"
  ) mapping + "</array>";

  hidutilJson = mapping: builtins.toJSON {
    UserKeyMapping = map (m: {
      HIDKeyboardModifierMappingSrc = m.src;
      HIDKeyboardModifierMappingDst = m.dst;
    }) mapping;
  };

  apply = kb: ''
    # ${kb.name}
    launchctl asuser "$(id -u -- ${username})" \
      sudo --user=${username} -- \
      defaults -currentHost write -g \
        com.apple.keyboard.modifiermapping.${toString kb.vendorId}-${toString kb.productId}-0 \
        '${defaultsXml kb.mapping}'
    hidutil property \
      --matching '${builtins.toJSON { VendorID = kb.vendorId; ProductID = kb.productId; }}' \
      --set '${hidutilJson kb.mapping}' >/dev/null \
      || echo "keyboards: couldn't apply the ${kb.name} mapping now; it applies on replug" >&2
  '';
in
{
  system.activationScripts.postActivation.text = lib.mkAfter
    (lib.concatMapStringsSep "\n" apply keyboards);
}
