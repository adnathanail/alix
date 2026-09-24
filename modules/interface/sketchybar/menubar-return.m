// A native menu-bar icon that hides the native menu bar again, i.e. returns
// to SketchyBar. The counterpart of config/items/menubar.lua's icon, which
// shows it.
//
// It doesn't touch the menu-bar setting itself: that goes through System
// Events, which needs an Automation grant, and this ad-hoc-signed Nix binary
// would lose any grant on every rebuild (see ./signing.nix). Instead it
// triggers a SketchyBar event, and SketchyBar — which has the grant, on its
// stably-signed path — does the hiding.
//
// No app bundle: a plain binary with the Accessory activation policy gets a
// status item without a Dock icon. While the menu bar is auto-hidden the
// icon simply isn't seen, so it runs all the time (launchd agent in
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
    item.button.toolTip = @"Hide the menu bar and return to SketchyBar";

    // target is a weak reference; `target` lives until main returns, which
    // is never while [app run] is running.
    ReturnTarget* target = [ReturnTarget new];
    item.button.target = target;
    item.button.action = @selector(hideMenuBar:);

    [app run];
  }
  return 0;
}
