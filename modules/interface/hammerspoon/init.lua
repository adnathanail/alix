-- Hammerspoon config. Nix-owned (modules/interface/hammerspoon/): edit it
-- there, not in ~/.config/hammerspoon.

-- Start at login, from Hammerspoon's own login item.
hs.autoLaunch(true)

-- Fn+<key> types a character: the ⌥-typed characters that AeroSpace's ⌥
-- bindings take over (British layout: ⌥2 €, ⌥3 #). Fn+digit means nothing
-- to macOS on its own, so nothing is lost.
--
-- The key press is rewritten in place — Fn cleared, the character put in
-- place of the key's own — rather than swallowed and re-typed. There's never
-- a ⌥ in it, so AeroSpace doesn't see a binding, and apps just get the text.
-- Key-ups too, so no app sees half of an Fn+<key> press.
local fnChars = {
  ["2"] = "€",
  ["3"] = "#",
}

local byKeycode = {}
for key, char in pairs(fnChars) do
  byKeycode[hs.keycodes.map[key]] = char
end

-- Global, so it isn't garbage-collected (which would stop the tap).
fnCharsTap = hs.eventtap.new(
  { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp },
  function(event)
    local char = byKeycode[event:getKeyCode()]
    if not char then return false end
    -- Fn alone: with anything else held it's some other shortcut.
    local flags = event:getFlags()
    if not flags:containExactly({ "fn" }) then return false end
    event:setFlags({})
    event:setUnicodeString(char)
    return false
  end
)
fnCharsTap:start()

-- Reload when Nix replaces this file (each `ns` that changes it). Global,
-- for the same reason as the tap.
configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/hammerspoon/", hs.reload):start()
