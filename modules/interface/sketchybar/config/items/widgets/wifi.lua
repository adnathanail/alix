local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "network_update"
-- for the network interface "en0", which is fired every 2.0 seconds.
sbar.exec("killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0")

local popup_width = 250

-- Shown in place of the up/down speeds when clicked; clicking again switches
-- back to the speeds.
local wifi_ssid = sbar.add("item", "widgets.wifi.ssid", {
  position = "right",
  drawing = false,
  padding_left = 0,
  icon = { drawing = false },
  label = {
    font = {
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
    max_chars = 18,
    string = "????????????",
  },
})

local wifi_up = sbar.add("item", "widgets.wifi1", {
  position = "right",
  padding_left = -5,
  width = 0,
  icon = {
    padding_right = 0,
    font = {
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    string = icons.wifi.upload,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = colors.red,
    string = "??? Bps",
  },
  y_offset = 4,
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
  position = "right",
  padding_left = -5,
  icon = {
    padding_right = 0,
    font = {
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    string = icons.wifi.download,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = colors.blue,
    string = "??? Bps",
  },
  y_offset = -4,
})

local wifi = sbar.add("item", "widgets.wifi.padding", {
  position = "right",
  label = { drawing = false },
})

-- Background around the item
local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", {
  wifi.name,
  wifi_up.name,
  wifi_down.name,
  wifi_ssid.name
}, {
  background = { color = colors.bg1 },
  popup = { align = "center", height = 30 }
})

local ssid = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    font = {
      style = settings.font.style_map["Bold"]
    },
    string = icons.wifi.router,
  },
  width = popup_width,
  align = "center",
  label = {
    font = {
      size = 15,
      style = settings.font.style_map["Bold"]
    },
    max_chars = 18,
    string = "????????????",
  },
  background = {
    height = 2,
    color = colors.grey,
    y_offset = -15
  }
})

local hostname = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = "Hostname:",
    width = popup_width / 2,
  },
  label = {
    max_chars = 20,
    string = "????????????",
    width = popup_width / 2,
    align = "right",
  }
})

local ip = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = "IP:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  }
})

local mask = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = "Subnet mask:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  }
})

local router = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = "Router:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
})

local open_settings = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    align = "left",
    string = icons.gear,
  },
  label = {
    align = "left",
    string = "Open Wi-Fi Settings",
  },
  width = popup_width,
})

sbar.add("item", { position = "right", width = settings.group_paddings })

wifi_up:subscribe("network_update", function(env)
  local up_color = (env.upload == "000 Bps") and colors.grey or colors.red
  local down_color = (env.download == "000 Bps") and colors.grey or colors.blue
  wifi_up:set({
    icon = { color = up_color },
    label = {
      string = env.upload,
      color = up_color
    }
  })
  wifi_down:set({
    icon = { color = down_color },
    label = {
      string = env.download,
      color = down_color
    }
  })
end)

-- Whether macOS flags the current network as a hotspot (expensive), pushed
-- in by the network_path event provider.
local hotspot = false

local function update_wifi_icon()
  sbar.exec("ipconfig getifaddr en0", function(ip)
    local connected = not (ip == "")
    local icon = icons.wifi.disconnected
    if connected then
      icon = hotspot and icons.wifi.hotspot or icons.wifi.connected
    end
    wifi:set({
      icon = {
        string = icon,
        color = connected and colors.white or colors.red,
      },
    })
  end)
end

-- macOS only reveals the SSID to processes with Location Services access,
-- so a helper (wifi-ssid.m beside config/ in the repo, its own launchd agent)
-- reads it and keeps it in this file, triggering wifi_ssid_change. The file
-- is empty while there's no network, and also while the helper has no
-- access — hence the interface check, to tell those apart.
local ssid_file = os.getenv("HOME") .. "/.cache/sketchybar/wifi-ssid"
sbar.add("event", "wifi_ssid_change")

local function get_ssid(callback)
  sbar.exec("ipconfig getsummary en0 | grep -Fxq '  Active : FALSE' || echo active", function(active)
    if type(active) ~= "string" or not active:find("active") then return callback("") end
    local file = io.open(ssid_file)
    local name = file and file:read("a") or ""
    if file then file:close() end
    name = name:gsub("%s+$", "")
    callback(name == "" and "Name unavailable" or name)
  end)
end

local function update_ssid()
  get_ssid(function(name)
    wifi_ssid:set({ label = name == "" and "Disconnected" or name })
  end)
end

wifi:subscribe({"wifi_change", "system_woke"}, function()
  update_wifi_icon()
  update_ssid()
end)

wifi:subscribe("wifi_ssid_change", update_ssid)

wifi:subscribe("hotspot_change", function(env)
  hotspot = env.hotspot == "on"
  update_wifi_icon()
end)

-- Started on `forced` (which fires once the initial config has loaded)
-- rather than at the top of the file: it only triggers on network changes,
-- so its first trigger has to land after this item has subscribed.
wifi:subscribe("forced", function(env)
  sbar.exec("killall network_path >/dev/null; $CONFIG_DIR/helpers/event_providers/network_path/bin/network_path hotspot_change")
end)

local function hide_details()
  wifi_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
  local should_draw = wifi_bracket:query().popup.drawing == "off"
  if should_draw then
    wifi_bracket:set({ popup = { drawing = true }})
    sbar.exec("networksetup -getcomputername", function(result)
      hostname:set({ label = result })
    end)
    sbar.exec("ipconfig getifaddr en0", function(result)
      ip:set({ label = result })
    end)
    get_ssid(function(name)
      ssid:set({ label = name })
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
      mask:set({ label = result })
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
      router:set({ label = result })
    end)
  else
    hide_details()
  end
end

-- Clicking the speeds (or the SSID standing in for them) swaps between the two.
local showing_ssid = false

local function toggle_ssid()
  showing_ssid = not showing_ssid
  if showing_ssid then update_ssid() end
  wifi_up:set({ drawing = not showing_ssid })
  wifi_down:set({ drawing = not showing_ssid })
  wifi_ssid:set({ drawing = showing_ssid })
end

wifi_up:subscribe("mouse.clicked", toggle_ssid)
wifi_down:subscribe("mouse.clicked", toggle_ssid)
wifi_ssid:subscribe("mouse.clicked", toggle_ssid)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  sbar.exec("echo \"" .. label .. "\" | pbcopy")
  sbar.set(env.NAME, { label = { string = icons.clipboard, align="center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)

open_settings:subscribe("mouse.clicked", function(env)
  hide_details()
  sbar.exec("open 'x-apple.systempreferences:com.apple.wifi-settings-extension'")
end)
