#!/bin/sh
export QML2_IMPORT_PATH="$HOME/.config/quickshell/caelestia/build/qml"
export QT_QPA_PLATFORM=wayland
export QT_ENABLE_HIGHDPI_SCALING=1

# Use the installed quickshell binary (AUR: quickshell-git), fall back
# to a legacy AppImage if present.
if command -v qs >/dev/null 2>&1; then
    QUICKSHELL="$(command -v qs)"
elif [ -x "$HOME/.local/bin/quickshell.AppImage" ]; then
    QUICKSHELL="$HOME/.local/bin/quickshell.AppImage"
else
    echo "quickshell binary not found; install quickshell-git" >&2
    exit 1
fi

# Kill any existing quickshell instance
killall quickshell 2>/dev/null
sleep 0.3

# Launch and restart on crash
while true; do
    "$QUICKSHELL" -p "$HOME/.config/quickshell/caelestia/shell.qml"
    sleep 2
done
