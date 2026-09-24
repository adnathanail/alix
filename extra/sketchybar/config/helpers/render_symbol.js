// Renders an SF Symbol, by name, to a PNG in one colour. Used by
// items/menubar.lua for its upright eye (SketchyBar can't rotate glyphs, so
// that icon is an image). Run with:
//   osascript -l JavaScript render_symbol.js <symbol> <out.png> <rrggbb> <points>
ObjC.import("AppKit");
function run(argv) {
  const [name, out, hex, points] = argv;
  const n = parseInt(hex, 16);
  const color = $.NSColor.colorWithSRGBRedGreenBlueAlpha(
    ((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255, 1);
  // Weight/scale as raw values: JXA crashes on the NSFontWeight* constants.
  // Weight 0 = regular; scale 2 = medium.
  const cfg = $.NSImageSymbolConfiguration
    .configurationWithPointSizeWeightScale(parseFloat(points), 0, 2)
    .configurationByApplyingConfiguration(
      $.NSImageSymbolConfiguration.configurationWithPaletteColors($([color])));
  const img = $.NSImage.imageWithSystemSymbolNameAccessibilityDescription(name, name)
    .imageWithSymbolConfiguration(cfg);
  const rep = $.NSBitmapImageRep.imageRepWithData(img.TIFFRepresentation);
  rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $.NSDictionary.dictionary)
    .writeToFileAtomically(out, true);
  return rep.pixelsWide + "x" + rep.pixelsHigh;
}
