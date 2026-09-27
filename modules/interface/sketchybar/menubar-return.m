// A native menu-bar icon that returns to SketchyBar, which then draws over
// the native menu bar again. The counterpart of config/items/menubar.lua's
// icon, which hides SketchyBar to show the native bar. It triggers a
// SketchyBar event, and SketchyBar un-hides itself.
//
// No app bundle: a plain binary with the Accessory activation policy gets a
// status item without a Dock icon. While SketchyBar covers the native bar
// the icon simply isn't seen, so it runs all the time (launchd agent in
// ./default.nix). @sketchybar@ is substituted with the store path at build.
#import <Cocoa/Cocoa.h>

@interface ReturnTarget : NSObject
- (void)hideMenuBar:(id)sender;
@end

@implementation ReturnTarget
- (void)hideMenuBar:(id)sender {
  NSTask* task = [NSTask new];
  task.executableURL = [NSURL fileURLWithPath:@"@sketchybar@/bin/sketchybar"];
  task.arguments = @[ @"--trigger", @"menubar_hide" ];
  NSError* error = nil;
  if (![task launchAndReturnError:&error])
    NSLog(@"menubar-return: couldn't run sketchybar: %@", error);
}
@end

int main(void) {
  @autoreleasepool {
    NSApplication* app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];

    NSStatusItem* item = [[NSStatusBar systemStatusBar]
        statusItemWithLength:NSSquareStatusItemLength];
    NSImage* image =
        [NSImage imageWithSystemSymbolName:@"eye.slash"
                  accessibilityDescription:@"Return to SketchyBar"];
    image.template = YES;
    item.button.image = image;
    item.button.toolTip = @"Return to SketchyBar";

    // target is a weak reference; `target` lives until main returns, which
    // is never while [app run] is running.
    ReturnTarget* target = [ReturnTarget new];
    item.button.target = target;
    item.button.action = @selector(hideMenuBar:);

    [app run];
  }
  return 0;
}
