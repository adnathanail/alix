-- Local change: driven by Spotify directly instead of SketchyBar's
-- media_change event, which never fires on this macOS — it's built on the
-- private MediaRemote framework, locked since macOS 15.3/15.4. (Upstream also
-- covered Music; this is Spotify only.)
--
-- Spotify broadcasts com.spotify.client.PlaybackStateChanged on every
-- play/pause/track change; on each one this asks Spotify over AppleScript for
-- the state, track and artwork URL, and caches the artwork to a file for the
-- cover image. The popup's buttons also go through Spotify's AppleScript
-- rather than nowplaying-cli, which uses the same locked framework.
-- SketchyBar needs Automation permission for Spotify (asked for once).

local icons = require("icons")
local colors = require("colors")

local function spotify(command)
  return "osascript -e 'tell application \"Spotify\" to " .. command .. "'"
end

local media_cover = sbar.add("item", {
  position = "right",
  background = {
    image = {
      string = "",
      -- Images draw at 1pt per pixel × scale. Covers are shrunk to 128px
      -- when cached (below), so this makes them 28pt, the bar's item height.
      scale = 28 / 128,
    },
    color = colors.transparent,
  },
  label = { drawing = false },
  icon = { drawing = false },
  drawing = false,
  updates = true,
  popup = {
    align = "center",
    horizontal = true,
  }
})

local media_artist = sbar.add("item", {
  position = "right",
  drawing = false,
  padding_left = 3,
  padding_right = 0,
  width = 0,
  icon = { drawing = false },
  label = {
    width = 0,
    font = { size = 9 },
    color = colors.with_alpha(colors.white, 0.6),
    max_chars = 18,
    y_offset = 6,
  },
})

local media_title = sbar.add("item", {
  position = "right",
  drawing = false,
  padding_left = 3,
  padding_right = 0,
  icon = { drawing = false },
  label = {
    font = { size = 11 },
    width = 0,
    max_chars = 16,
    y_offset = -5,
  },
})

sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.back },
  label = { drawing = false },
  click_script = spotify("previous track"),
})
sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.play_pause },
  label = { drawing = false },
  click_script = spotify("playpause"),
})
sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.forward },
  label = { drawing = false },
  click_script = spotify("next track"),
})

local interrupt = 0
local function animate_detail(detail)
  if (not detail) then interrupt = interrupt - 1 end
  if interrupt > 0 and (not detail) then return end

  sbar.animate("tanh", 30, function()
    media_artist:set({ label = { width = detail and "dynamic" or 0 } })
    media_title:set({ label = { width = detail and "dynamic" or 0 } })
  end)
end

-- One line each: state, title, artist, artwork URL — or just "stopped".
-- Checks Spotify is running first, so asking never launches it.
local query = "osascript"
  .. " -e 'if application \"Spotify\" is not running then return \"stopped\"'"
  .. " -e 'tell application \"Spotify\"'"
  .. " -e 'if player state is stopped then return \"stopped\"'"
  .. " -e 'set t to current track'"
  .. " -e 'return (player state as text) & linefeed & (name of t) & linefeed"
  .. " & (artist of t) & linefeed & (artwork url of t)'"
  .. " -e 'end tell'"

-- Downloads the cover once per track (the URL's last segment is unique to
-- the image), clearing the previous one, shrinks it to 128px (Spotify's are
-- 640px — still sharp at 28pt on Retina) and prints the local path.
local function cache_artwork(url, callback)
  local file = url:match("([%w]+)$")
  if not url:match("^https://") or not file then return callback(nil) end
  sbar.exec("d=\"$HOME/Library/Caches/sketchybar\"; f=\"$d/spotify-" .. file
    .. ".jpg\"; mkdir -p \"$d\"; [ -s \"$f\" ] || { rm -f \"$d\"/spotify-*.jpg;"
    .. " curl -sfL '" .. url .. "' -o \"$f\" && sips -Z 128 \"$f\" >/dev/null; };"
    .. " [ -s \"$f\" ] && printf %s \"$f\"",
    function(path) callback(path ~= "" and path or nil) end)
end

local last_title = nil
local function update()
  sbar.exec(query, function(result)
    local lines = {}
    for line in result:gmatch("[^\n]+") do lines[#lines + 1] = line end
    local state, title, artist, url = lines[1], lines[2], lines[3], lines[4]

    local drawing = (state == "playing")
    media_artist:set({ drawing = drawing, label = artist or "" })
    media_title:set({ drawing = drawing, label = title or "" })
    media_cover:set({ drawing = drawing })

    if not drawing then
      media_cover:set({ popup = { drawing = false } })
      return
    end

    cache_artwork(url or "", function(path)
      media_cover:set({ background = { image = { string = path or "" } } })
    end)

    -- Slide the details out briefly on a new track (not on every resume).
    if title ~= last_title then
      last_title = title
      animate_detail(true)
      interrupt = interrupt + 1
      sbar.delay(5, animate_detail)
    end
  end)
end

sbar.add("event", "spotify_change", "com.spotify.client.PlaybackStateChanged")
media_cover:subscribe({ "spotify_change", "system_woke" }, update)
update()

media_cover:subscribe("mouse.entered", function(env)
  interrupt = interrupt + 1
  animate_detail(true)
end)

media_cover:subscribe("mouse.exited", function(env)
  animate_detail(false)
end)

media_cover:subscribe("mouse.clicked", function(env)
  media_cover:set({ popup = { drawing = "toggle" }})
end)

media_title:subscribe("mouse.exited.global", function(env)
  media_cover:set({ popup = { drawing = false }})
end)
