// Triggers <event-name> with hotspot=on|off whenever the system's default
// network path changes. "Hotspot" is macOS's own expensive-network flag
// (nw_path_is_expensive), which it sets for iPhone Personal Hotspot and for
// Android hotspots that announce themselves as metered.
#include <Network/Network.h>
#include "../sketchybar.h"

int main (int argc, char** argv) {
  if (argc < 2) {
    printf("Usage: %s \"<event-name>\"\n", argv[0]);
    exit(1);
  }

  char event_message[512];
  snprintf(event_message, 512, "--add event '%s'", argv[1]);
  sketchybar(event_message);

  nw_path_monitor_t monitor = nw_path_monitor_create();
  nw_path_monitor_set_queue(monitor, dispatch_get_main_queue());
  nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
    char trigger_message[512];
    snprintf(trigger_message,
             512,
             "--trigger '%s' hotspot=%s",
             argv[1],
             nw_path_is_expensive(path) ? "on" : "off");
    sketchybar(trigger_message);
  });
  nw_path_monitor_start(monitor);
  dispatch_main();
}
