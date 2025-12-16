-- Open mission control shortcut-works with stickies

-- This function brings an app to the foreground and triggers Mission Control
function showAppMissionControl(appName)
    local app = hs.application.get(appName)
    
    if app then
        app:activate()  -- Activate the app
        -- Trigger Mission Control (Application Exposé)
        hs.eventtap.keyStroke({ "fn", "ctrl" }, "down")  -- Adjust key combo if needed
    end
end

local hyper = {"cmd", "alt", "ctrl"}
hs.hotkey.bind(hyper, 'space', function()
    showAppMissionControl('Stickies')
end)

-- Ctrl+J/K for down/up arrow navigation with smooth key repeat
-- Function to simulate proper key press and release events
local function simulateKeyPress(key)
    return function()
        hs.eventtap.event.newKeyEvent({}, key, true):post()
        hs.eventtap.event.newKeyEvent({}, key, false):post()
    end
end

-- Bind Ctrl+H to Left Arrow with smooth repeat
hs.hotkey.bind({"ctrl"}, "h", simulateKeyPress("left"), nil, simulateKeyPress("left"))

-- Bind Ctrl+J to Down Arrow with smooth repeat
hs.hotkey.bind({"ctrl"}, "j", simulateKeyPress("down"), nil, simulateKeyPress("down"))

-- Bind Ctrl+K to Up Arrow with smooth repeat  
hs.hotkey.bind({"ctrl"}, "k", simulateKeyPress("up"), nil, simulateKeyPress("up"))

-- Bind Ctrl+L to Right Arrow with smooth repeat
hs.hotkey.bind({"ctrl"}, "l", simulateKeyPress("right"), nil, simulateKeyPress("right"))

-- Text selection shortcuts with Ctrl+Shift+h/j/k/l (or Shift+Ctrl)
-- Function to simulate key press with shift modifier for selection
local function simulateSelectionKeyPress(key)
    return function()
        hs.eventtap.event.newKeyEvent({"shift"}, key, true):post()
        hs.eventtap.event.newKeyEvent({"shift"}, key, false):post()
    end
end

-- Bind Shift+Ctrl+H to Shift+Left Arrow (select left)
hs.hotkey.bind({"shift", "ctrl"}, "h", simulateSelectionKeyPress("left"), nil, simulateSelectionKeyPress("left"))

-- Bind Shift+Ctrl+J to Shift+Down Arrow (select down)
hs.hotkey.bind({"shift", "ctrl"}, "j", simulateSelectionKeyPress("down"), nil, simulateSelectionKeyPress("down"))

-- Bind Shift+Ctrl+K to Shift+Up Arrow (select up)
hs.hotkey.bind({"shift", "ctrl"}, "k", simulateSelectionKeyPress("up"), nil, simulateSelectionKeyPress("up"))

-- Bind Shift+Ctrl+L to Shift+Right Arrow (select right)
hs.hotkey.bind({"shift", "ctrl"}, "l", simulateSelectionKeyPress("right"), nil, simulateSelectionKeyPress("right"))

-- Bind Cmd+; to Delete (backspace)
hs.hotkey.bind({"cmd"}, ";", simulateKeyPress("delete"), nil, simulateKeyPress("delete"))

-- Bind Cmd+Shift+A to Enter
hs.hotkey.bind({"cmd", "shift"}, "a", simulateKeyPress("return"), nil, simulateKeyPress("return"))

-- Hotkey to reload Hammerspoon config
hs.hotkey.bind({"cmd", "ctrl", "shift"}, "R", function()
  hs.reload()
end)