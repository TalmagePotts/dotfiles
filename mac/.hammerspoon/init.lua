-- Caps Lock to Control
local capsLockPressed = false
hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(e)
    if e:getKeyCode() == 57 then
        local newCapsLockState = e:getFlags()["caps"]
        if newCapsLockState ~= capsLockPressed then
            capsLockPressed = newCapsLockState
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, capsLockPressed):post()
        end
        return true
    end
    return false
end):start()

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

-- Option+letter (top row) to numbers: Option+Q=1, Option+W=2, ..., Option+P=0
local numberMap = {
    q = "1", w = "2", e = "3", r = "4", t = "5",
    y = "6", u = "7", i = "8", o = "9", p = "0"
}

for letter, number in pairs(numberMap) do
    hs.hotkey.bind({"alt"}, letter, function()
        hs.eventtap.keyStroke({}, number)
    end)
end

-- Option+Shift+letter to symbols above numbers: Option+Shift+Q=!, Option+Shift+W=@, etc.
local symbolMap = {
    q = "1", w = "2", e = "3", r = "4", t = "5",
    y = "6", u = "7", i = "8", o = "9", p = "0"
}

for letter, number in pairs(symbolMap) do
    hs.hotkey.bind({"alt", "shift"}, letter, function()
        hs.eventtap.keyStroke({"shift"}, number)
    end)
end

-- Option+[ to hyphen
hs.hotkey.bind({"alt"}, "[", function()
    hs.eventtap.keyStroke({}, "-")
end)

-- Option+Shift+[ (Option+{) to em dash
hs.hotkey.bind({"alt", "shift"}, "[", function()
    hs.eventtap.keyStroke({}, "—")
end)

-- Hotkey to reload Hammerspoon config
hs.hotkey.bind({"cmd", "ctrl", "shift"}, "R", function()
  hs.reload()
end)

local scriptsDir = os.getenv("HOME") .. "/code/exfunct/"

local function runScript(name)
  local result, success = hs.execute(scriptsDir .. name, true)
  if success then
    hs.alert.show("✓ " .. name .. " done")
  else
    hs.alert.show("✗ " .. name .. " failed")
  end
end

hs.hotkey.bind({"cmd", "ctrl", "shift"}, "C", function()
  local output, success, termType, rc = hs.execute(os.getenv("HOME") .. "/code/exfunct/runclipocr", true)
  hs.alert.show("success: " .. tostring(success) .. "\n" .. output)
end)