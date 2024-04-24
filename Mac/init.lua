local fastKeyStroke = function(modifiers, character)
  local event = require("hs.eventtap").event
  event.newKeyEvent(modifiers, string.lower(character), true):post()
  event.newKeyEvent(modifiers, string.lower(character), false):post()
end

-- Hammerspoon hotkeys
hs.hotkey.bindSpec({ { "ctrl", "cmd", "alt" }, "y" }, hs.toggleConsole)
hs.hotkey.bindSpec({ { "ctrl", "cmd", "alt" }, "r" }, hs.reload)

-- Move a character
hs.hotkey.bind("cmd", "j", function() fastKeyStroke("", "left") end)
hs.hotkey.bind("cmd", "k", function() fastKeyStroke("", "down") end)
hs.hotkey.bind("cmd", "l", function() fastKeyStroke("", "right") end)
hs.hotkey.bind("cmd", "i", function() fastKeyStroke("", "up") end)
-- Move a character with highlight
hs.hotkey.bind({"cmd", "shift"}, "j", function() fastKeyStroke("shift", "left") end)
hs.hotkey.bind({"cmd", "shift"}, "k", function() fastKeyStroke("shift", "down") end)
hs.hotkey.bind({"cmd", "shift"}, "l", function() fastKeyStroke("shift", "right") end)
hs.hotkey.bind({"cmd", "shift"}, "i", function() fastKeyStroke("shift", "up") end)
-- Move home/end
hs.hotkey.bind("cmd", "u", function() fastKeyStroke("cmd", "left") end)
hs.hotkey.bind("cmd", "o", function() fastKeyStroke("cmd", "right") end)
hs.hotkey.bind("alt", "u", function() fastKeyStroke("cmd", "left") end)
hs.hotkey.bind("alt", "o", function() fastKeyStroke("cmd", "right") end)
-- Move home/end with highlight
hs.hotkey.bind({"cmd", "shift"}, "o", function() fastKeyStroke({"cmd", "shift"}, "right") end)
hs.hotkey.bind({"cmd", "shift"}, "u", function() fastKeyStroke({"cmd", "shift"}, "left") end)
hs.hotkey.bind({"alt", "shift"}, "o", function() fastKeyStroke({"cmd", "shift"}, "right") end)
hs.hotkey.bind({"alt", "shift"}, "u", function() fastKeyStroke({"cmd", "shift"}, "left") end)
-- Move a word
hs.hotkey.bind("alt", "j", function() fastKeyStroke("alt", "left") end)
hs.hotkey.bind("alt", "k", function() fastKeyStroke("", "down") end)
hs.hotkey.bind("alt", "l", function() fastKeyStroke("alt", "right") end)
hs.hotkey.bind("alt", "i", function() fastKeyStroke("", "up") end)
-- Move a word with highlight
hs.hotkey.bind({"alt", "shift"}, "j", function() fastKeyStroke({"alt", "shift"}, "left") end)
hs.hotkey.bind({"alt", "shift"}, "k", function() fastKeyStroke("shift", "down") end)
hs.hotkey.bind({"alt", "shift"}, "l", function() fastKeyStroke({"alt", "shift"}, "right") end)
hs.hotkey.bind({"alt", "shift"}, "i", function() fastKeyStroke("shift", "up") end)
-- Move 5 lines up/down, 3 words left/right
hs.hotkey.bind("ctrl", "k", function() for i=1,5 do fastKeyStroke("", "down") end end)
hs.hotkey.bind("ctrl", "i", function() for i=1,5 do fastKeyStroke("", "up") end end)
hs.hotkey.bind("ctrl", "j", function() for i=1,3 do fastKeyStroke("alt", "left") end end)
hs.hotkey.bind("ctrl", "l", function() for i=1,3 do fastKeyStroke("alt", "right") end end)
-- Backspace
-- hs.hotkey.bind("cmd", "e", function() fastKeyStroke("", "delete") end)
hs.hotkey.bind("cmd", "e", function() fastKeyStroke("", "return") end)