-- Copies the current selection, waits a moment, then sends to copycat server
tell application "System Events"
    keystroke "c" using command down
    delay 0.2
end tell

do shell script "$HOME/.local/bin/copycat cp"
