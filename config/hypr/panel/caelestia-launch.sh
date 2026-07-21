#!/bin/sh
export QML2_IMPORT_PATH="$HOME/.config/quickshell/caelestia/build/qml"
export QT_QPA_PLATFORM=wayland
export QT_ENABLE_HIGHDPI_SCALING=1

QUICKSHELL="/home/rigby/.local/bin/quickshell.AppImage"

# Kill any existing quickshell instance
killall quickshell 2>/dev/null
sleep 0.3

# Launch and restart on crash
while true; do
    "$QUICKSHELL" -p "$HOME/.config/quickshell/caelestia/shell.qml"
    sleep 2
done
