// Publishes the current Wi-Fi network's name (SSID) for the bar's wifi
// widget (config/items/widgets/wifi.lua): writes it to
// ~/.cache/sketchybar/wifi-ssid (empty when there's none) and triggers the
// `wifi_ssid_change` event, at startup and whenever the network changes.
//
// macOS only reveals the SSID to processes with Location Services access,
// and only lists an app bundle there, so this is built as one
// (./default.nix) with an NSLocationUsageDescription, run by its own launchd
// agent rather than as SketchyBar's child — a child's request would be
// attributed to SketchyBar, which has no bundle. Without access, CoreWLAN
// returns no SSID, so the name stays empty. @sketchybar@ is substituted with
// the store path at build.
#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreWLAN/CoreWLAN.h>

@interface Publisher : NSObject <CLLocationManagerDelegate, CWEventDelegate>
@property(strong) CLLocationManager* location;
@property(strong) CWWiFiClient* wifi;
@property(copy) NSString* path;
- (void)publish;
@end

@implementation Publisher
- (void)publish {
  NSString* ssid = self.wifi.interface.ssid ?: @"";
  NSError* error = nil;
  [[NSFileManager defaultManager]
            createDirectoryAtPath:[self.path stringByDeletingLastPathComponent]
      withIntermediateDirectories:YES
                       attributes:nil
                            error:nil];
  if (![ssid writeToFile:self.path
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:&error])
    NSLog(@"wifi-ssid: couldn't write %@: %@", self.path, error);

  NSTask* task = [NSTask new];
  task.executableURL = [NSURL fileURLWithPath:@"@sketchybar@/bin/sketchybar"];
  task.arguments = @[ @"--trigger", @"wifi_ssid_change" ];
  if (![task launchAndReturnError:&error])
    NSLog(@"wifi-ssid: couldn't run sketchybar: %@", error);
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager*)manager {
  [self publish];
}

// CoreWLAN calls these on its own queue.
- (void)ssidDidChangeForWiFiInterfaceWithName:(NSString*)name {
  dispatch_async(dispatch_get_main_queue(), ^{ [self publish]; });
}

- (void)linkDidChangeForWiFiInterfaceWithName:(NSString*)name {
  dispatch_async(dispatch_get_main_queue(), ^{ [self publish]; });
}
@end

int main(void) {
  @autoreleasepool {
    NSApplication* app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];

    Publisher* publisher = [Publisher new];
    publisher.path = [NSHomeDirectory()
        stringByAppendingPathComponent:@".cache/sketchybar/wifi-ssid"];

    publisher.wifi = [CWWiFiClient sharedWiFiClient];
    publisher.wifi.delegate = publisher;
    NSError* error = nil;
    for (NSNumber* type in @[ @(CWEventTypeSSIDDidChange),
                              @(CWEventTypeLinkDidChange) ]) {
      if (![publisher.wifi startMonitoringEventWithType:type.integerValue
                                                  error:&error])
        NSLog(@"wifi-ssid: couldn't monitor Wi-Fi events: %@", error);
    }

    // The delegate gets an initial authorization callback, which publishes.
    // Asking only while undetermined shows the prompt once; after that the
    // toggle lives in System Settings → Privacy & Security → Location
    // Services.
    publisher.location = [CLLocationManager new];
    publisher.location.delegate = publisher;
    if (publisher.location.authorizationStatus ==
        kCLAuthorizationStatusNotDetermined)
      [publisher.location requestWhenInUseAuthorization];

    [app run];
  }
  return 0;
}
