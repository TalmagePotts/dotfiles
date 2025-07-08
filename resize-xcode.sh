#!/bin/bash

# Simulator on right using System Events
osascript -e '
tell application "Simulator" to activate
tell application "System Events" to tell process "Simulator"
    set position of front window to {1226, 0}
    set size of front window to {695, 1072}
end tell'

# Xcode on left
osascript -e 'tell application "Xcode" to set bounds of front window to {0, 0, 1225, 1072}'
osascript -e 'tell application "Xcode" to activate'

