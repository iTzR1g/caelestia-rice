#!/usr/bin/env sh

QS="${QS:-$(command -v qs)}"
[ -z "$QS" ] && [ -x "$HOME/.local/bin/quickshell.AppImage" ] && QS="$HOME/.local/bin/quickshell.AppImage"

env QML_XHR_ALLOW_FILE_READ=1 \
    QT_QPA_PLATFORM=wayland \
    "$QS" \
    --path "$HOME/.config/hypr/panel/hover-panel.qml"
