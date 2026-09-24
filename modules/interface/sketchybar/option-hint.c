// Tells SketchyBar when Option is being held on its own, so it can show the
// AeroSpace key hints (config/items/aerospace_mode.lua). SketchyBar has no
// modifier-key events of its own.
//
// Polls the modifier state every 50ms rather than tapping key events: an
// event tap needs an Input Monitoring grant, which this ad-hoc-signed Nix
// binary would lose on every rebuild (see ./signing.nix); reading the
// current flags needs none. The hint shows after Option has been held for
// HOLD_MS, so quick ⌥-shortcuts and ⌥-typed characters don't flash it, and
// hides as soon as it's released. ⌘ or ⌃ held alongside means some other
// shortcut, so they suppress it. Runs as a launchd agent (./default.nix);
// @sketchybar@ is substituted with the store path at build.
#include <ApplicationServices/ApplicationServices.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>

#define POLL_MS 50
#define HOLD_MS 400

extern char** environ;

static void trigger(const char* held) {
  char* argv[] = { "sketchybar", "--trigger", "aerospace_option_hint",
                   (char*)held, NULL };
  pid_t pid;
  if (posix_spawn(&pid, "@sketchybar@/bin/sketchybar", NULL, NULL, argv,
                  environ) == 0)
    waitpid(pid, NULL, 0);
}

int main(void) {
  int held_ms = 0;
  int shown = 0;
  for (;;) {
    CGEventFlags flags =
        CGEventSourceFlagsState(kCGEventSourceStateHIDSystemState);
    int option = (flags & kCGEventFlagMaskAlternate) &&
                 !(flags & (kCGEventFlagMaskCommand | kCGEventFlagMaskControl));

    held_ms = option ? held_ms + POLL_MS : 0;
    if (!shown && held_ms >= HOLD_MS) {
      trigger("HELD=on");
      shown = 1;
    } else if (shown && !option) {
      trigger("HELD=off");
      shown = 0;
    }
    usleep(POLL_MS * 1000);
  }
}
